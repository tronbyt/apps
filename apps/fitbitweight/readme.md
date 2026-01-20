# FitbitWeight for Tidbyt

Displays your weight, and optionally, your body fat percentage or BMI from Fitbit. You can enter your data manually into Fitbit, or you can get a supported scale like the Aria to automatically update your fitbit whenever you weight yourself.

Motivate yourself by displaying your progress!

Instructions:

Step 1: Register Your Fitbit App
Go to https://dev.fitbit.com/apps and sign in with your Fitbit account

Click Register an App

Fill out the form:

Application Name: TronbyT Weight Tracker (or anything)

Description: Displays Fitbit weight data on TronbyT

Application Website: https://tronbyt.com (or any URL)

Organization: Your name

Organization Website: Any URL

OAuth 2.0 Application Type: Personal (not Client)

Redirect URL: http://localhost/ ← EXACTLY this with trailing slash

Terms of Service URL: https://example.com

Privacy Policy URL: https://example.com

Click Create

Step 2: Copy Your Credentials

After creation, you'll see:


OAuth 2.0 Client ID: 99XXXX         ← Copy this
Client Secret:    3faf91e18b4799... ← Copy this  

Step 3: 

Open this URL (replace YOUR_CLIENT_ID):

https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=YOUR_CLIENT_ID&redirect_uri=http://localhost/&scope=weight

When you log in and approve, you'll be redirected to a URL like this:

http://localhost/?code=1747cff2357579c7d594fce4738445f87abb28cd#_=_

Copy the "Code" without the #_=_ garbage at the end of the line. In this case the code you need is:
1747cff2357579c7d594fce4738445f87abb28cd

Step 4:

Enter the Fitbit Client ID and Fitbit Client Secret as the first two config items. Then paste the above "Fitbit Auth Code".

Select the period, measurement and secondary measurement you want to display.

![FitbitWeight for Tidbyt](fitbitweight.gif)
