#!/bin/sh
set -e

# Wings runs the container as an arbitrary uid with no /etc/passwd entry; Postgres refuses to
# start without one, and the rootfs is read-only, so fake it with nss_wrapper.
cuid="$(id -u)"; cgid="$(id -g)"
printf 'container:x:%s:%s:container:/home/container:/bin/sh\n' "$cuid" "$cgid" > /tmp/nss_passwd
printf 'container:x:%s:\n' "$cgid" > /tmp/nss_group
export NSS_WRAPPER_PASSWD=/tmp/nss_passwd
export NSS_WRAPPER_GROUP=/tmp/nss_group
export LD_PRELOAD="$(find /usr -name 'libnss_wrapper.so*' 2>/dev/null | head -n1)"

PGBIN="$(dirname "$(find /usr -type f -name initdb 2>/dev/null | head -n1)")"
export PATH="$PGBIN:$PATH"

export PGDATA="/home/container/postgres"
REDISDIR="/home/container/redis"
mkdir -p "$PGDATA" "$REDISDIR"
chmod 700 "$PGDATA"

if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[init] Creating PostgreSQL cluster..."
    initdb -D "$PGDATA" --username=postgres --auth-local=trust --auth-host=trust >/dev/null
fi

pg_ctl -D "$PGDATA" -o "-c listen_addresses='' -c unix_socket_directories=/tmp" -w start

if ! psql -h /tmp -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='logger'" | grep -q 1; then
    echo "[init] Creating logger role and database..."
    psql -h /tmp -U postgres -v ON_ERROR_STOP=1 <<'SQL'
CREATE USER logger WITH PASSWORD 'logger';
CREATE DATABASE logger OWNER logger;
SQL
fi

# Schema from upstream's src/miscellaneous/generateDB.js, which we can't run as-is (it assumes an
# empty server). Idempotent and run every boot, so a schema change ships with an image rebuild.
psql -h /tmp -U logger -d logger -v ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE IF NOT EXISTS messages ( id TEXT PRIMARY KEY, author_id TEXT NOT NULL, content TEXT, attachment_b64 TEXT, ts TIMESTAMPTZ );
CREATE TABLE IF NOT EXISTS guilds ( id TEXT PRIMARY KEY, owner_id TEXT NOT NULL, ignored_channels TEXT[], disabled_events TEXT[], event_logs JSON, log_bots BOOL, custom_settings JSON );
SQL

pg_ctl -D "$PGDATA" -m fast -w stop

# Message content is AES-encrypted at rest. A blank key would silently encrypt everything with
# "undefined", so generate one once and keep it — losing this file makes stored messages unreadable.
if [ -z "$AES_KEY" ]; then
    KEYFILE="/home/container/aes.key"
    if [ ! -s "$KEYFILE" ]; then
        echo "[init] No AES key set, generating one at $KEYFILE"
        head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$KEYFILE"
    fi
    AES_KEY="$(cat "$KEYFILE")"
    export AES_KEY
fi

export PGHOST="127.0.0.1" PGPORT="5432" PGUSER="logger" PGPASSWORD="logger" PGDATABASE="logger"
export REDIS_HOST="127.0.0.1" REDIS_PORT="6379"
# parseInt(undefined) is NaN, which breaks the redlock startup lock and the message batcher.
export REDIS_LOCK_TTL="${REDIS_LOCK_TTL:-2000}"
export MESSAGE_BATCH_SIZE="${MESSAGE_BATCH_SIZE:-10}"
export GLOBAL_BOT_PREFIX="${GLOBAL_BOT_PREFIX:-v3}"
export CREATOR_IDS="${CREATOR_IDS:-}"

echo "[init] Starting Postgres, Redis and wikilogger via supervisord..."
exec supervisord -c /etc/supervisord.conf
