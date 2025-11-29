#Shows total number of Workspace ONE UEM devices by type in all OGs.
#
#by Craig J. Johnston
#email: ibanyan@gmail.com

# Import the required libraries
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/wsicon.png", WSICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

WSICON = WSICON_ASSET.readall()

#Set the fonts
FONT = "tom-thumb"
HFONT = "5x8"

#Define the items that make up the query to the WS1 tenant.
#Set the root OG ID.
#Look at the number at the end of the URL after navigating to OG Details page.
# og = ""

#Set your tenant code.
#AirWatchAPI Key in the REST API screen.
# tenantcode = ""

#Set the API admin user's username and password.  Today this app only supports Basic authentication.
#It will be encoded into Base64 for you.
# adminuser = ""
# adminpassword = ""
# authotmp = base64.encode(adminuser + ":" + adminpassword)
# autho = "Basic " + authotmp

#Set your tenant's API url.
#This is your tenant URL but changing cn to as.
# tenanturl = ""

#The actual API query.  Don't change this.
query = "/API/mdm/devices/devicecountinfo?organizationgroupid="

#we use this call just to get the Root OG name.
rootogquery = "/API/system/groups/devicecounts?organizationgroupid="

#Set the API URLs by adding the tenanturl, query, and og variables together.
# AWDEVICES_API_URL = tenanturl + query + og
# AWROOTOG_URL = tenanturl + rootogquery + og

#Create the WS1 icon.  This icon is a PNG file that was encoded with base64 by using:
# base64 -i logofilename.png |pbcopy
#in Terminal on a Mac.  Piping it to pbcopy puts it directly into the clipboard so it can be pasted into the app.
#We then ask to have the base64 decoded back into the icon image.

# Main function to render the Tidbyt app

#Here we are calling the API and including all the headers.  We check to make sure it returns a HTTP 200.
#If not, we fail the app which makes it stop.

#The first API call we use to get the Root OG name.  The second one retuns the device info we are looking for.

#When the JSON data comes back from this API call, it doesn't include a key if the value is 0, so we have to first
# check to see if its there before we try and get the value, otherwise the app stops with an error.

DEFAULT_OGI = "11536"
DEFAULT_TENNANTCODEI = "W2+l8YG+rrWWFUI6v9E+6lE+Tef8fQZYt4VMj7ATEzY="
DEFAULT_TENANTURLI = "https://as1506.awmdm.com"
DEFAULT_ADMINUSERI = "apiguy3"
DEFAULT_ADMINPASSWORDI = "VMware2!"

# TidByt likes an app to run without errors when you submit it, so you have to provide default values.
# This is why we provide DEFAULT values above.
# To accept input from the user in the TidByt app, you change the def main(): to def main (config):
# then you get the input from the values defined in the Schema section of the app (in this case its at the bottom).
# So when you do config.get("ogi"), the variable "ogi" is defined in the schema.
# You also have to provide a fallback or DEFAULT value in case the user never inputs anything, but also so that your app runs
# when its being run by PIXLET on your computer since PIXLET doesn't ask for input.

def main(config):
    og = config.get("ogi", DEFAULT_OGI)
    tenantcode = config.get("tenantcodei", DEFAULT_TENNANTCODEI)
    tenanturl = config.get("tenanturli", DEFAULT_TENANTURLI)
    adminuser = config.get("adminuseri", DEFAULT_ADMINUSERI)
    adminpassword = config.get("adminpasswordi", DEFAULT_ADMINPASSWORDI)

    authotmp = base64.encode(adminuser + ":" + adminpassword)
    autho = "Basic " + authotmp

    #Set the API URLs by adding the tenanturl, query, and og variables together.
    AWDEVICES_API_URL = tenanturl + query + og
    AWROOTOG_URL = tenanturl + rootogquery + og

    rep = http.get(AWROOTOG_URL, headers = {"Authorization": autho, "Accept": "application/json", "aw-tenant-code": tenantcode})
    if rep.status_code != 200:
        print("URL %s" % AWROOTOG_URL)
        fail("The request failed with status %d", rep.status_code)

    rootog = rep.json()["LocationGroups"][0]["LocationGroupName"]

    rep = http.get(AWDEVICES_API_URL, headers = {"Authorization": autho, "Accept": "application/json", "aw-tenant-code": tenantcode})
    if rep.status_code != 200:
        print("URL %s" % AWDEVICES_API_URL)
        fail("The request failed with status %d", rep.status_code)

    TotalmacOS = 0.0
    TotalAndroid = 0.0
    TotaliOS = 0.0
    TotalWindows = 0.0

    if (rep.json()["Platforms"].get("Apple")) == None:
        iOS = 0
    else:
        iOS = rep.json()["Platforms"]["Apple"]
        TotaliOS += iOS

    if (rep.json()["Platforms"].get("Android")) == None:
        Android = 0
    else:
        Android = rep.json()["Platforms"]["Android"]
        TotalAndroid += Android

    if (rep.json()["Platforms"].get("AppleOsX")) == None:
        macOS = 0
    else:
        macOS = rep.json()["Platforms"]["AppleOsX"]
        TotalmacOS += macOS

    if (rep.json()["Platforms"].get("WindowsRT")) == None:
        Windows = 0
    else:
        Windows = rep.json()["Platforms"]["WindowsRT"]
        TotalWindows += Windows

    #Now that we have the values we need, we can put them on the screen.
    #We render a column so that all items (or children as they are called) are vertically laid out.
    #The children of the column are then listed between the [ and ].
    #For the first child we render a row because we want to put the WS1 icon next to the root OG name.
    #Further when rendering the root OG name we do it as a Marquee so it scrolls.
    #This is because we don't know how long this name will be.
    #The rest of the children are the the name of the value and the value itself.
    #We use the Height value to make the height of the row 1 pixel higher than the top of the text.
    #This provides a nice 1 pixel space between each row.

    return render.Root(
        child = render.Column(
            # Column is a vertical children layout
            children = [
                render.Row(
                    children = [
                        render.Image(src = WSICON),
                        render.Marquee(
                            width = 64,
                            child = render.Text("%s" % rootog, font = HFONT, color = "#00a"),
                        ),
                    ],
                ),
                render.Text(
                    content = "Android:%s" % humanize.ftoa(TotalAndroid, 0),
                    height = 6,
                    font = FONT,
                ),
                render.Text(
                    content = "iOS:    %s" % humanize.ftoa(TotaliOS, 0),
                    height = 6,
                    font = FONT,
                ),
                render.Text(
                    content = "macOS:  %s" % humanize.ftoa(TotalmacOS, 0),
                    height = 6,
                    font = FONT,
                ),
                render.Text(
                    content = "Windows:%s" % humanize.ftoa(TotalWindows, 0),
                    height = 6,
                    font = FONT,
                ),
            ],
        ),
    )

# Below is the Schema section.  Before you ask users to input values into the TidByt app, you have to define those
# values here in the schema section.  Also the variable names you use here, are used in the def main(config): section
# So when you set an id = "ogi" here you are defining the variable that must be used above when you do a config.get.
# The names of the icons used must be specific.  On your computer type:
# pixlet community list-icons
# to list all possible icon names.

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ogi",
                name = "Root Organization Group ID",
                desc = "The number at the end of the URL after navigating to OG Details page.",
                icon = "pager",
            ),
            schema.Text(
                id = "tenantcodei",
                name = "Tenant Code",
                desc = "AirWatchAPI Key in the REST API screen.",
                icon = "code",
            ),
            schema.Text(
                id = "tenanturli",
                name = "Tenant URL",
                desc = "This is your tenant URL but changing cn to as.",
                icon = "html5",
            ),
            schema.Text(
                id = "adminuseri",
                name = "API Admin's Username",
                desc = "Username for the API admin user.",
                icon = "person",
            ),
            schema.Text(
                id = "adminpasswordi",
                name = "API Admin's Password",
                desc = "Password for the API admin user.",
                icon = "unlock",
                secret = True,
            ),
        ],
    )
