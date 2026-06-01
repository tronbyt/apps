"""
Applet: WiFi QR Code
Summary: Creates a WiFi QR code
Description: This app creates a scannable WiFi QR code. It is not compatible with Enterprise networks. Since there are display limitations with the Tidbyt, not all networks will be able to be encoded. Simply scan the QR code and your phone will join the WiFi network.
Author: misusage
"""

load("images/wifi_icon.png", WIFI_ICON_ASSET = "file")
load("qrcode.star", "qrcode")
load("render.star", "render")
load("schema.star", "schema")

WIFI_ICON = WIFI_ICON_ASSET.readall()

def get_schema():
    options = [
        schema.Option(
            display = "WEP",
            value = "WEP",
        ),
        schema.Option(
            display = "WPA/WPA2/WPA3 - Personal",
            value = "WPA",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ssid",
                name = "SSID",
                desc = "What is your network name/SSID?",
                icon = "wifi",
                default = "",
            ),
            schema.Text(
                id = "password",
                name = "Password",
                desc = "What is your WiFi Password?",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Dropdown(
                id = "encryption",
                name = "Authentication Method",
                desc = "What is the authentication method for your WiFi?",
                icon = "lock",
                default = options[1].value,
                options = options,
            ),
        ],
    )

def main(config):
    ssid = config.str("ssid", None)
    password = config.str("password", "")
    encryption = config.get("encryption", "WPA")

    if (ssid == None):
        show = render.Stack(
            children = [
                render.Column(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.WrappedText(
                                    align = "center",
                                    content = "WiFi QR Code Generator",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        )

    else:
        url = "WIFI:T:" + encryption + ";S:" + ssid + ";P:" + password + ";;"

        if (len(url) >= 56):
            show = render.Stack(
                children = [
                    render.Column(
                        main_align = "center",
                        expanded = True,
                        children = [
                            render.Row(
                                main_align = "space_around",
                                expanded = True,
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.WrappedText("ERROR: Your network is not compatible."),
                                        offset_start = 32,
                                        offset_end = 32,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            )

        else:
            qifi = qrcode.generate(
                url = url,
                size = "large",
                color = "#fff",
                background = "#000",
            )

            show = render.Stack(
                children = [
                    render.Column(
                        main_align = "center",
                        expanded = True,
                        children = [
                            render.Row(
                                main_align = "space_around",
                                expanded = True,
                                children = [
                                    render.Padding(
                                        pad = (0, 1, 0, 0),
                                        child = render.Image(src = qifi),
                                    ),
                                    render.Image(src = WIFI_ICON),
                                ],
                            ),
                        ],
                    ),
                ],
            )

    return render.Root(
        child = show,
    )
