var http = require('http');
const axios = require('axios');
const host = '0.0.0.0';
const port = '6969';
const plexServerHost = 'localhost';
const plexServerPort = '32400';
const API_KEY = "<CUSTOM_API_HERE>";

const server = http.createServer(async (req, res) => {
    if ((req.headers['x-api-key'] || '') != API_KEY) {
        res.writeHead(401);
        res.end();
        return;
    }
    if (req.method === "GET") {
        // `/status/sessions` is included for future plex tidbyt app idea (currently watching, you can remove if you'd like)
        if (req.url.includes("/library/recentlyAdded") || req.url.includes("/status/sessions") || req.url.includes("/library/metadata")) {
            const requestUrl = new URL(req.url, `http://${req.headers.host}`);
            const pathname = requestUrl.pathname;
            const _type = pathname.includes("/library/metadata") ? 'image/jpeg' : 'application/json';

            try {
                const targetUrl = new URL(`http://${plexServerHost}:${plexServerPort}`);
                targetUrl.pathname = pathname;
                targetUrl.search = requestUrl.search;
                targetUrl.searchParams.set('X-Plex-Token', req.headers['x-plex-token']);

                const response = await axios({
                    method: 'GET',
                    url: targetUrl.href,
                    headers: {
                        'accept': _type
                    },
                    responseType: 'arraybuffer'
                });

                res.writeHead(200, { 'Content-Type': _type });
                res.write(response.data);
                res.end();
                console.log(`requested plex at ${Date()}`);
            } catch (error) {
                console.error(error);
                res.writeHead(500);
                res.end();
            }
        }
    } else {
        res.writeHead(404);
        res.end();
    }
});

server.listen(port, host, () => {
    console.log(`Plex (tidbyt) proxy server running on http://${host}:${port}`)
})