# ---- build stage: fetch wikilogger and install its deps (eris comes from a git fork) ----
FROM alpine:3.22 AS build
ARG WIKILOGGER_VERSION=main
RUN apk add --no-cache nodejs npm git
# Busts the layer cache whenever upstream moves, so a rebuild actually picks up new commits.
ADD https://api.github.com/repos/fee1-dead/wikilogger/commits/${WIKILOGGER_VERSION} /tmp/upstream.json
RUN git clone --depth 1 --branch ${WIKILOGGER_VERSION} https://github.com/fee1-dead/wikilogger.git /src
WORKDIR /src
# Logger's intent list predates Discord's messageContent intent, and this Eris fork has no name
# for it either. Without it Discord blanks every message body and delete/edit logs come out empty,
# which is the entire point of the bot. 32768 = 1 << 15. grep first so the build fails loudly
# if upstream restructures instead of silently shipping a bot that logs nothing.
RUN grep -q "'guildMessages'," src/bot/index.js && \
    sed -i "s/'guildMessages',/'guildMessages',\n      32768, \/\/ messageContent/" src/bot/index.js
RUN npm ci --omit=dev && rm -rf /src/.git

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
