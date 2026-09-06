# wikilogger on Pterodactyl

Run [wikilogger](https://github.com/fee1-dead/wikilogger) — the Wikimedia fork
of [Logger](https://github.com/curtisf/logger), a Discord audit-logging bot —
as a single Pterodactyl server. Postgres, Redis and the bot all live in one
container managed by supervisord, and every bit of state sits under
`/home/container` so it survives restarts and reinstalls.

Upstream expects a machine with Postgres and Redis already installed and an
`.env` file next to the source. Pterodactyl gives you one container per server
and configures it with environment variables, so this squeezes the whole thing
into that one container and drives it from egg variables instead.

## How it works

- Built from source in a multi-stage Dockerfile — there are no prebuilt
  releases, and `eris` is pulled from a git fork, so the build stage needs npm
  and git.
- On first boot `entrypoint.sh` initialises the Postgres cluster, creates the
  `logger` role and database, and applies the schema from upstream's
  `generateDB.js`. The schema statements are `IF NOT EXISTS` and run on every
  boot, so a later image rebuild can add tables to an existing server.
- Postgres and Redis bind to loopback only — never exposed through a
  Pterodactyl allocation. The bot has no web interface, so the server's
  allocated port goes unused.
- The bot runs Node's `cluster` module and sizes its worker pool from the CPU
  count and Discord's recommended shard count. One worker is the normal case
  for a self-host.

## Setup

1. Create the application at
   [discord.com/developers](https://discord.com/developers/applications) and,
   under **Bot → Privileged Gateway Intents**, enable **Server Members Intent**
   and **Message Content Intent**. Both are mandatory: the bot requests them at
   identify and Discord refuses the connection if they are not enabled.
2. Create the server from this egg, fill in **Bot Token** and **Creator ID**
   (your own Discord user ID), and start it.
3. Invite the bot with the `bot` and `applications.commands` scopes, plus
   Manage Webhooks, View Audit Log, Read Messages and Send Messages.
4. Register the slash commands — this is a manual one-time step upstream never
   automated. With **Enable Text Commands** left at `true`, send `v3setcmd
   global` in any channel the bot can see (`v3` being the **Command Prefix**).
   Global commands take up to an hour to appear; `v3setcmd guild` registers
   them in that one server immediately.
5. Run `/setup` in the server you want logged.

## Variables

| Variable | What it does |
|----------|--------------|
| Bot Token | Raw token, no `Bot ` prefix |
| Creator ID | Your Discord user ID; gates the hidden owner commands, including `setcmd` |
| Enable Text Commands | Any non-empty value enables them (including `"false"` — blank is the off switch) |
| Command Prefix | Prefix for those text commands, default `v3` |
| AES Key | Encrypts logged message content; generated into `/home/container/aes.key` when blank |
| Message Batch Size | Cached messages flushed to Postgres per batch |
| Redis Lock TTL | Milliseconds a shard holds the startup lock while connecting |
| Error Webhook URL | Optional Discord webhook for the bot's own errors; blank disables the notifier |
| Sentry DSN | Optional exception reporting |
| Paste Endpoint / Token | Optional haste-server style endpoint for `/archive` and bulk-delete logs |

Upstream also reads `BEZERK_*`, `TWILIGHT_*`, `ZABBIX_HOST`,
`STAT_SUBMISSION_INTERVAL` and `USE_MAX_CONCURRENCY`. Those belong to the
public bot's own infrastructure and are left out of the egg; add them as extra
server variables if you actually run that infrastructure.

## Things to know

- **The messageContent patch.** The intent list in upstream's
  `src/bot/index.js` predates Discord's `messageContent` intent, and the `eris`
  fork has no name for it either. Without it Discord blanks every message body
  and the delete/edit logs come out empty, so the Dockerfile injects the raw
  intent bit at build time. The build fails loudly if upstream restructures
  that list.
- **Message retention is unbounded.** Upstream's `.env.example` mentions
  `MESSAGE_HISTORY_DAYS`, but nothing in the code reads it and there is no
  pruning job. The `messages` table grows until you prune it yourself.
- **Losing `/home/container/aes.key` makes stored messages unreadable.** Back
  it up with the rest of the server if the log history matters.
- **Memory.** Postgres, Redis and a Node cluster in one container: give the
  server at least 1 GB.

## Releases

Every push to `main` builds and pushes `:latest`, `:main` and `:sha-…` to GHCR,
so committing and pushing is enough to get an importable egg. Tagging also
publishes `:X.Y.Z` and `:X.Y`.

```sh
git tag v1.0.0
git push origin v1.0.0
```

The bot source is baked into the image at build time. To pick up new upstream
commits, re-run the workflow — the `main` build always fetches the current tip,
and **Run workflow** takes a `wikilogger_version` ref if you want a specific
tag or commit.

See [CHANGELOG.md](CHANGELOG.md) for what changed between versions.

## Files

| File | What it is |
|------|-----------|
| `Dockerfile` | Two-stage build: fetch and install wikilogger, then assemble the runtime image |
| `entrypoint.sh` | First-boot DB setup, schema, key generation, and handoff to supervisord |
| `supervisord.conf` | Keeps Postgres, Redis and the bot running |
| `egg-wikilogger.json` | The Pterodactyl egg you import |
| `.github/workflows/docker.yml` | Builds and pushes the image to GHCR |

## License

The packaging in this repo is [MIT](LICENSE). wikilogger itself is
AGPL-3.0-or-later; the image built here contains it, so anything you distribute
from that image carries the AGPL's terms.
