# Changelog

Notable changes to this egg. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions are git tags.

## [Unreleased]

- Forked the bot into `bot/` with `git subtree`, keeping upstream history. The
  image now builds from this repo instead of cloning `fee1-dead/wikilogger` at
  build time, so bot changes ship by pushing them.
- The `messageContent` intent is now a source change in `bot/src/bot/index.js`
  rather than a `sed` in the Dockerfile.

## [1.0.0]

First working version.

- All-in-one image: Postgres 16 + Redis + wikilogger under supervisord, built
  in a multi-stage Dockerfile from `fee1-dead/wikilogger`.
- State kept under `/home/container`; Postgres and Redis bound to loopback.
- Database role, database and schema created on first boot; schema statements
  re-run every boot so an image rebuild can add tables.
- `AES_KEY` generated and persisted on first boot when left blank.
- Build-time patch adding Discord's `messageContent` intent, without which the
  bot logs empty message bodies.
- Pterodactyl egg (`egg-wikilogger.json`) with variables for the token, creator
  ID, prefix and the optional webhook/Sentry/paste integrations.
- GitHub Actions workflow that builds and pushes the image to GHCR.
