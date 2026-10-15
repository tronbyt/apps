# Tronbyt Server Updates

Shows when a new version of [Tronbyt Server](https://github.com/tronbyt/server) is available, with the version your server is running and the new one. By default it only appears on your display when there's an update, and skips its turn the rest of the time. Turn off **Only show when there's an update** to also see a screen saying your server is up to date, so you know it's working.

## Setting it up

Usually there's nothing to set. The app runs inside your Tronbyt server and checks it at `http://localhost:8000`, the address Tronbyt Server uses unless it's been changed. If your server listens on a different port, set **Server address** to match, e.g. `http://localhost:9000`.

## How it works

- **Your server's version** comes from the bottom of its login page, which shows e.g. "Server v2.4.0" and doesn't need you to be signed in. It's checked every 30 minutes.
- **The latest version** comes from [Tronbyt Server's releases on GitHub](https://github.com/tronbyt/server/releases), checked every 6 hours. If GitHub can't be reached, the last version found is used.
- If the app can't connect to your server, it shows "Can't connect to your Tronbyt server" every other time its turn comes round, until it can.

Tronbyt Server checks for new versions itself and shows "Update available!" at the bottom of its web pages. This app puts the same news on your display.

## Run Tronbyt on your Umbrel

My [saltedlolly App Store](https://github.com/saltedlolly/umbrel-app-store) is a community app store for [Umbrel](https://umbrel.com) with apps I've packaged for it, including **Tronbyt**: a Tronbyt server that runs on your Umbrel. To add the store:

1. Open the **App Store** on your Umbrel.
2. Click **•••** in the top right, then **Community App Stores**.
3. Paste `https://github.com/saltedlolly/umbrel-app-store` and click **Add**.
4. Click **Open** next to "saltedlolly App Store".

Community app stores aren't official Umbrel services. Back up your data, and test an app before relying on it.

## Author

[saltedlolly](https://github.com/saltedlolly)
