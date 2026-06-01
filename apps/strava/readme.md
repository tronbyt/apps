# Strava for Tronbyt

Display your Strava Data on your Tronbyt device

Instructions:

1. 

Register Strava App (if not done)
Go to https://www.strava.com/settings/api

Click "Create New API Application"

Enter: Name="Tronbyt App", Website="http://localhost", OAuth Redirect="http://localhost"

Save. Note your Client ID and Client Secret (14-digit numbers).

2. 

Replace YOUR_CLIENT_ID in this URL:
https://www.strava.com/oauth/mobile/authorize?client_id=YOUR_CLIENT_ID&response_type=code&redirect_uri=http://localhost&approval_prompt=force&scope=read,profile:read_all,activity:read

Going to this URL will post back to localhost and probably be an error page. But YOUR_AUTHORIZATION_CODE will be in the URL on the querystring called CODE. Copy that value for step 3. 

3. 

Open terminal/command prompt and run this curl command (replace YOUR_CLIENT_ID,  YOUR_CLIENT_SECRET and YOUR_AUTHORIZATION_CODE):

```bash
curl -X POST "https://www.strava.com/api/v3/oauth/token" \
  -d client_id=YOUR_CLIENT_ID \
  -d client_secret=YOUR_CLIENT_SECRET \
  -d code=YOUR_AUTHORIZATION_CODE \
  -d grant_type=authorization_code
  ```

Response will include:

text
{
  "access_token": "abc123...",
  "refresh_token": "def456...",
  "expires_at": 1736788800,
  "token_type": "Bearer"
}

4. Configure the Tronbyt App

Enter the Strava Refresh Token, Strava Client ID and Strava Secret from above in the config fields.

Note: The documentation suggest your token could expire after 6 hours. That's not been my experience, however, this code should renew your token if it expires as long as the code runs at least once every 6 hours. It's possible your token stored on Tronbyt expires and wont' work. In that case, follow the above steps and enter the new Refresh Token in the configuration for the App and Save.

5. Run the App

![Strava for Tronbyt](strava.webp)
