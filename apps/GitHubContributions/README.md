
#Github Contributions

Instructions to get a Personal Access Token:
1. Go to github.com → Profile Picture  → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token
2. Name: "Tronbyt Contributions" | Expiration: 90 days | Select Repositories | Permissions: Add 
3. Copy the token (ghp_xxx...) - you won't see it again!

Fine Grained:

Repositories: Metadata: Read Only
Account: Email Address: Read Only
Account: Profile: Read Only

YOUR_TOKEN = github_pat_XXXXXXXXxxxxxxxXXXXXXxx

To test, you can replace YOUR_USERNAME and YOUR_TOKEN in the following curl call:

curl -H "Authorization: bearer YOUR_TOKEN" \
-H "Content-Type: application/json" \
https://api.github.com/graphql \
-d '{
  "query": "query($u:String!, $from:DateTime!, $to:DateTime!) { user(login:$u) { contributionsCollection(from:$from, to:$to) { contributionCalendar { totalContributions weeks { firstDay contributionDays { date contributionCount } } } } } }",
  "variables": {
    "u": "YOUR_USERNAME",
    "from": "2025-10-18T00:00:00Z",
    "to": "2026-01-09T23:59:59Z"
  }
}'

![GitHub Contributions for Tronbyt](githubcontributions.webp)