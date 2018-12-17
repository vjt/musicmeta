require 'oauth2'
require 'pry'
require 'json'
require 'optparse'
#require 'byebug'

$options = {}
$parser = OptionParser.new do |opts|
  opts.banner = "Usage: #$0 -u USER -i APPID -s SECRET -d DOMAIN [options]"

  opts.on('-u', '--user USERID', 'Provide user id') do |v|
    $options[:userid] = v
  end

  opts.on('-i', '--appid APPID', 'Provide app id') do |v|
    $options[:appid] = v
  end

  opts.on('-s', '--secret SECRET', 'Provide app secret') do |v|
    $options[:secret] = v
  end

  opts.on('-d', '--domain DOMAIN', 'Provide app domain for callback') do |v|
    $options[:domain] = v
  end

  opts.on('-t', '--token TOKEN', 'Provide an access token') do |v|
    $options[:token] ||= {}
    $options[:token][:access_token] = v
  end

  opts.on('-e', '--expires EXPIRES', 'Access token expiration') do |v|
    $options[:token] ||= {}
    $options[:token][:expires_at] = v
  end

  opts.on('-f', '--fetch TYPES', 'Select what to fetch, separated by commas. Default: artists,albums,tracks') do |v|
    $options[:fetch] = v.split(',')
  end

  opts.on('-c', '--console', 'Start a console after authenticating') do |v|
    $options[:console] = true
  end
end

$parser.parse!

def bark(message)
  $stderr.puts message
  puts $parser.help

  exit 1
end

unless $options[:userid]
  bark "The --userid option is required"
end

$options[:fetch] ||= %w( artists albums tracks )

client = OAuth2::Client.new($options[:appid], $options[:secret],
  site:          'https://api.deezer.com/',
  token_url:     'https://connect.deezer.com/oauth/access_token.php',
  authorize_url: 'https://connect.deezer.com/oauth/auth.php')

if $options[:token]
  unless $options[:token].values_at(:access_token, :expires_at).compact.size == 2
    bark "Both --token and --expires are required to re-use an access token"
  end

  $token = OAuth2::AccessToken.from_hash(client, $options[:token])
  puts "Re-using previous access token #{$token.token} expiring at #{$token.expires_at}"

else

  unless $options.values_at(:appid, :secret, :domain).compact.size == 3
    bark "The --appid, --secret and --domain options are required"
  end

  auth_url = client.auth_code.authorize_url(redirect_uri: $options[:domain], perms: 'offline_access,manage_library,listening_history')
  puts "Please go here: #{auth_url}"
  print "Please provide access code: "
  auth_code = $stdin.readline.chomp

  $token = client.auth_code.get_token(auth_code, redirect_uri: $options[:domain], parse: :query)
  puts "Obtained access token #{$token.token}, expiring at #{$token.expires_at} (#{Time.at($token.expires_at)})"
end

$token.options[:mode] = :query

def fetch_user(item)
  fetch_all("user/#{$options[:userid]}/#{item}")

rescue => e
  puts "Error while fetching user #{item}: #{e}"
  nil
end

def fetch_all(url)
  ret = []

  loop do
    puts "Fetching #{url}..."

    contents = fetch_one(url)
    ret.concat contents['data']
    url = contents['next']
    break unless url
  end

  ret
end

def fetch_one(url)
  response = $token.get(url, mode: :query)

  if response.status != 200 || response.parsed.key?("error")
    $stderr.puts "Request to #{url} failed with status #{response.status}"
    pp response.parsed
    raise "Request error"
  end

  response.parsed
end

if $options[:console]
  puts "Starting an interactive console. Use $token.get() to perform requests to the API."
  Pry.start(binding)

else

  dump = $options[:fetch].inject({}) do |h, item|
    puts "\e[1;31mExtracting #{item}...\e[0m"

    h.update(item => fetch_user(item))
  end

  dumpfile = "dump-#{Time.now.strftime('%Y%m%d-%H%M%S')}.json"

  File.open(dumpfile, 'w+') {|f| f.write(dump.to_json) }

  puts "\e[1;32mOutput written to #{dumpfile}\e[0m"
end
