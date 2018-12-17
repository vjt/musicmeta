# Music Meta Fetcher

This is a gripe of mine, the ability to extract my favorites out of music
services. Useful both as a record of my habits, that should remain property of
myself and not the music service I rent music from, and also for pushing back
the favorites to another music service when swiching.

## Current status

I am recently moving from Deezer to YouTube Music / Google Play Music, so I
needed a way to extract all of my favorites out of Deezer to re-profile myself
on the other service.

At the moment, dumping all data from Deezer to a JSON file works.

## Usage

```
git clone https://github.com/vjt/musicmeta
bundle
ruby deezer.rb -h
```

And read help. To read from Deezer, you will need to create a new application
and pass the app id and secret. If you have internet presence on your domain,
then define that domain in the app, and pass the same domain to the `-d`
option.

For instance, my app is configured on the `sindro.me` domain, and I pass
`https://sindro.me/oauth` to the `-d` option. There is nothing listening on
`/oauth`, but Deezer will redirect you to `/oauth?code=foobar`, and you need
only to pass that authorization code to the Ruby script when asked.

Then the oauth token and expiration time will be printed, that you can re-use
in future invocations using the `-t` and `-e` options.

## Future plans

* Define an intermediate representation
* Implement a write adapter to Google Play Music
* Convert the Deezer bare-bone code to a read-only adapter for Deezer
* Await that somebody will implement this for Spotify ;-)
