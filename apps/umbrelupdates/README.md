# Umbrel Updates

Shows which apps on your [Umbrel](https://umbrel.com) home server have an update available, with each app's new version. When everything is up to date it says so, or it can skip its turn on your display until there's something to update.

It covers apps from the official Umbrel App Store and from any community app stores you've added to your Umbrel.

## What you need

- **umbrelOS 2.0 or later.** Earlier versions don't have the update check this app uses.
- **A Tronbyt server that can reach your Umbrel** on your network. If your Tronbyt server runs on the Umbrel itself, see [Run Tronbyt on your Umbrel](#run-tronbyt-on-your-umbrel) below.

## Setting it up

The app needs your Umbrel's address and a **device token**: a sign-in for this app that lasts until you sign it out. You get the token once, by signing in to your Umbrel from a computer on the same network. Your password is only sent to your Umbrel, and isn't stored anywhere.

On a Mac or Linux computer, paste this into a terminal (Windows: run it with `python`):

```sh
python3 - <<'PYEOF'
import getpass, json, urllib.request
url = (input("Umbrel address [http://umbrel.local]: ") or "http://umbrel.local").rstrip("/")
body = {
    "password": getpass.getpass("Umbrel password: "),
    "client": {"id": "tronbyt-umbrel-updates", "platform": "tronbyt", "deviceClass": "display",
               "appVersion": "1.0", "appBuild": "1", "osVersion": "pixlet"},
}
code = input("2FA code (leave empty if you don't use 2FA): ")
if code:
    body["totpToken"] = code
request = urllib.request.Request(url + "/trpc/user.loginNative", json.dumps(body).encode(), {"Content-Type": "application/json"})
print("\nDevice token:", json.load(urllib.request.urlopen(request))["result"]["data"]["deviceToken"])
PYEOF
```

Then, in the app's settings on your Tronbyt server:

- **Umbrel address**: your Umbrel's IP address on your network, e.g. `http://192.168.1.20`. Use the IP address rather than `umbrel.local`, which often doesn't work from inside a server.
- **Device token**: the token printed above.

If the app can't reach your Umbrel (for example, while it's restarting), it's skipped on your display until it can.

### Keeping your Umbrel safe

The device token can do anything your Umbrel account can, because umbrelOS doesn't offer read-only access to its update check. Treat it like a password: it's stored as a secret on your Tronbyt server, and only sent to your Umbrel. To stop the app using it, sign out its session from the list of signed-in devices in your Umbrel's settings; it's listed as a Tronbyt display.

## Run Tronbyt on your Umbrel

My [saltedlolly App Store](https://github.com/saltedlolly/umbrel-app-store) is a community app store for Umbrel with apps I've packaged for it, including **Tronbyt**: a Tronbyt server that runs on your Umbrel, so your displays don't depend on anyone else's servers. To add the store:

1. Open the **App Store** on your Umbrel.
2. Click **•••** in the top right, then **Community App Stores**.
3. Paste `https://github.com/saltedlolly/umbrel-app-store` and click **Add**.
4. Click **Open** next to "saltedlolly App Store".

Community app stores aren't official Umbrel services. Back up your data, and test an app before relying on it.

## Author

[saltedlolly](https://github.com/saltedlolly)
