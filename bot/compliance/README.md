## Application Details
### What does your application do? Please be as detailed as possible, and feel free to include links to image or video examples.

This bot logs events on a Discord server and sends them to a dedicated channel to aid with moderation. Some logged events could include: a message was deleted, a message was edited, a user joined a voice chat channel, a user left the server, etc.

See https://github.com/fee1-dead/wikilogger/tree/main/compliance/s1.png for an example screenshot.

### Do you have a public Privacy Policy telling your users about their data usage?

Yes

### Where is your Privacy Policy available?

The bot's bio has it, it is also displayed when users run /help or /info on any server with the bot added.

### Please share a link to your Privacy Policy.

https://github.com/fee1-dead/wikilogger/blob/main/PRIVACY.md

### Privileged Gateway Intents

- [x] Server Members Intent
- [ ] Presence Intent
- [x] Message Content Intent

## Server Members Intent

### Why do you need the Guild Members intent?

The bot needs to log when a user joins or leaves the server. This is a core functionality of the bot.

### Please provide links to screenshots and/or videos that demonstrate your use case

See https://github.com/fee1-dead/wikilogger/tree/main/compliance/s2.png.

### Are you storing any API Data off-platform (outside of Discord)?

No.

## Message Content Intent

### Can users opt-out of having their message content data tracked?

No.

### Are you storing message content data off-platform (outside of Discord)?

Yes.

### Are you storing user message content data for 30 days or less?

Yes.

### How do users contact you to request deletion of their activity data?

/clearmydata provides directions, the Privacy Policy linked above also provides directions (email ent3rm4n@gmail.com, DM beef.w, or join https://en.wikipedia.org/wiki/Wikipedia:Discord)

### Are you encrypting the data that you store at rest, as is required by our developer policy?

Yes.

### Will the message content data be used to train machine learning or AI Models?

No.

### Why do you need the Message Content intent?

The bot needs to be able to recover the original message when a message is deleted or updated in a server, in order to send moderation logs.

### Please provide links to screenshots and/or videos that demonstrate your use case

See https://github.com/fee1-dead/wikilogger/tree/main/compliance/s1.png for an example screenshot.
