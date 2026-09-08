# ---- build stage: install deps (eris comes from a git fork, so npm needs git) ----
FROM alpine:3.22 AS build
RUN apk add --no-cache nodejs npm git
# Manifests first so editing bot code doesn't reinstall every dependency.
COPY bot/package.json bot/package-lock.json /src/
WORKDIR /src
RUN npm ci --omit=dev
COPY bot/ /src/

# ---- runtime stage: Postgres + Redis + Supervisor + the bot, all in one image ----
FROM alpine:3.22
RUN apk add --no-cache \
    ca-certificates tzdata nodejs \
    postgresql16 postgresql16-contrib \
    redis supervisor nss_wrapper

RUN adduser -D -h /home/container container

COPY --from=build /src /app
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER container
ENV USER=container HOME=/home/container NODE_ENV=production
WORKDIR /home/container
CMD ["sh", "/entrypoint.sh"]
