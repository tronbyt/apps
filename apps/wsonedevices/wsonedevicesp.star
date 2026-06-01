#Shows total number and status of Workspace ONE UEM devices in all OGs.
#
#by Craig J. Johnston
#email: ibanyan@gmail.com

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/wsicon.png", WSICON_ASSET = "file")

# Import the required libraries
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
query = "/API/system/groups/devicecounts?organizationgroupid="

#Set the API URL by adding the tenanturl, query, and og vsariables together.
# AWDEVICES_API_URL = tenanturl + query + og

#Create the WS1 icon.  This icon is a PNG file that was encoded with base64 by using:
# base64 -i logofilename.png |pbcopy
#in Terminal on a Mac.  Piping it to pbcopy puts it directly into the clipboard so it can be pasted into the app.
#We then ask to have the base64 decoded back into the icon image.

# Main function to render the Tidbyt app

#Here we are calling the API and including all the headers.  We check to make sure it returns a HTTP 200.
#If not, we fail the app which makes it stop.

#When the JSON data comes back from this API call, it has a value at the bottom called "Total".
#This is actually the total number of OGs (or as it appears in the JSON file "LocationGroups"),
#and so we put the number we find there into the variable totalog.
#We also look for the root OG name at LocationGroup 0 and put its value in rootog.
#We then set the rest of the variables to 0.

#After this we use the totalog variable to create a FOR loop.  The loop starts at 0 and counts to the value
#stored in totalog.
#Inside this loop we grab the info we need from each LocationGroup.
#Because the returned JSON doesn't include a key if the value is 0, we have to first check to seee if its there
#before we try and get the value, otherwise the app stops with an error.

DEFAULT_OGI = "11536"
DEFAULT_TENNANTCODEI = "W2+l8YG+rrWWFUI6v9E+6lE+Tef8fQZYt4VMj7ATEzY="
DEFAULT_TENANTURLI = "https://as1506.awmdm.com"
DEFAULT_ADMINUSERI = "apiguy3"
DEFAULT_ADMINPASSWORDI = "VMware2!"

def main(config):
    og = config.get("ogi", DEFAULT_OGI)
    tenantcode = config.get("tenantcodei", DEFAULT_TENNANTCODEI)
    tenanturl = config.get("tenanturli", DEFAULT_TENANTURLI)
    adminuser = config.get("adminuseri", DEFAULT_ADMINUSERI)
    adminpassword = config.get("adminpasswordi", DEFAULT_ADMINPASSWORDI)

    authotmp = base64.encode(adminuser + ":" + adminpassword)
    autho = "Basic " + authotmp

    #Set the API URL by adding the tenanturl, query, and og vsariables together.
    AWDEVICES_API_URL = tenanturl + query + og

    rep = http.get(AWDEVICES_API_URL, headers = {"Authorization": autho, "Accept": "application/json", "aw-tenant-code": tenantcode})
    if rep.status_code != 200:
        print("URL %s" % AWDEVICES_API_URL)
        print("The request failed with status %d" % rep.status_code)
        return render.Root(
            child = render.WrappedText("API Error: %d" % rep.status_code, color = "#ff0000"),
        )

    totalog = rep.json()["Total"]
    rootog = rep.json()["LocationGroups"][0]["LocationGroupName"]
    totaldevices = 0.0
    totalunenrolled = 0.0
    totalenrolled = 0.0
    totalenrollp = 0.0

    for i in range(int(totalog)):
        if (rep.json()["LocationGroups"][i].get("TotalDevices")) == None:
            devicecount = 0
        else:
            devicecount = rep.json()["LocationGroups"][i]["TotalDevices"]
            totaldevices += devicecount

        if (rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"].get("EnrollmentInProgress")) == None:
            enrollp = 0
        else:
            enrollp = rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"]["EnrollmentInProgress"]
            totalenrollp += enrollp

        if (rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"].get("Enrolled")) == None:
            enrolled = 0
        else:
            enrolled = rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"]["Enrolled"]
            totalenrolled += enrolled

        if (rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"].get("Unenrolled")) == None:
            unenrolled = 0
        else:
            unenrolled = rep.json()["LocationGroups"][i]["DeviceCountByEnrollmentStatus"]["Unenrolled"]
            totalunenrolled += unenrolled

    #Now that we have the values we need, we can put them on the screen.
    #We render a column so that all items (or children as they are called) are vertically laid out.
    #The children of the column are then listed between the [ and ].
    #For the first child we render a row because we want to put the WS1 icon next to the root OG name.
    #Further when rendering the root OG name we do it as a Marquee so it scrolls.
    #This is because we don't know how long this name will be.
    #The rest of the children are the the name of the value and the value itself.
    #We also use the humanize.ftoa function to remove the .0 from each number.
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
                            child = render.Text("%s" % rootog, font = HFONT, color = "#1270cd"),
                        ),
                    ],
                ),
                render.Text(
                    content = "Total:     %s" % humanize.ftoa(totaldevices, 0),
                    height = 6,
                    font = FONT,
                ),
                render.Text(
                    content = "Pending:   %s" % humanize.ftoa(totalenrollp, 0),
                    height = 6,
                    font = FONT,
                ),
                render.Text(
                    content = "Enrolled:  %s" % humanize.ftoa(totalenrolled, 0),
                    height = 6,
                    font = FONT,
                ),
                render.Text(
                    content = "Unenrolled:%s" % humanize.ftoa(totalunenrolled, 0),
                    height = 6,
                    font = FONT,
                ),
            ],
        ),
    )

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
