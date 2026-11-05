# Gartner News for Tidbyt

Displays the latest headlines from Gartner.com's RSS feed.

Gartner, Inc. is a technological research and consulting firm based in Stamford, Connecticut that conducts research on technology and shares this research both through private consulting as well as executive programs and conferences. Its clients include large corporations, government agencies, technology companies, and investment firms.

![Gartner News for Tidbyt](gartner_news.webp)

## If it doesn't appear

Gartner's website is protected by Cloudflare, which decides for each request whether it looks like it's from a person or a bot. Sometimes it shows a challenge (a CAPTCHA) instead of the news feed, which an app can't complete. In January 2026 this blocked the app completely, and it was marked broken until October 2026, when the feed was available again.

When the feed is blocked, the app skips its turn on your display rather than showing an error, and your Tronbyt server's log says "Gartner's news feed isn't available". Cloudflare's decisions can depend on your server's internet address, so the app may work on one server and not another, and may start or stop working without any change to the app. It only fetches the feed every 6 hours, so it won't add to the problem.
