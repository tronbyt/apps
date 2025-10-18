"""
Applet: Enphase summary
Summary: Enphase daily, monthly, annual and lifetime summary
Description: Daily, monthly, annual and lifetime energy production and consumption for your Enphase solar system (via proxy)
Author: Converted from SolarEdge version by ckyr
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

# Cache for 5 minutes (300 seconds)
CACHE_TTL = 300

# Colors
GRAY = "#777777"
RED = "#AA0000"
GREEN = "#00FF00"
WHITE = "#FFFFFF"

# Icons (same as original)
SUN_SUM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAJZlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgExAAIAAAARAAAAWodpAAQAAAABAAAAbAAAAAAAAABIAAAAAQAAAEgAAAABd3d3Lmlua3NjYXBlLm9yZwAAAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAAqgAwAEAAAAAQAAAAoAAAAAFL8o+gAAAAlwSFlzAAALEwAACxMBAJqcGAAAAi1pVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx4bXA6Q3JlYXRvclRvb2w+d3d3Lmlua3NjYXBlLm9yZzwveG1wOkNyZWF0b3JUb29sPgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj43MjwvdGlmZjpZUmVzb2x1dGlvbj4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHRpZmY6WFJlc29sdXRpb24+NzI8L3RpZmY6WFJlc29sdXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgp0/eNQAAABK0lEQVQYGU2QvUpDQRCFz+xujJCACKKgFoKdjyAEa30AYyX+pIqgtfaCT2CV2ElQe7E26WMj2JqAYKGF5N549+7uuJNIyIEtZvg45+yAGYQppe3qmbypFYQxRODhc7UWmD9KW/ePXumu4cACJp3qtgJWiO4aRhYCsaIl93p8FMcDjh72Zf8hDPLcMd6FmcQKpOdmmsg8IH5Fgu3/nBc3W1cjMG3vncb4bmG+dKlndcUPnQWRQpYbm9qeIlP3wa3FCiM+9v0XSQoT5z7yQPSPYp5E81vtEOXCDZIcfmChywb2K4vRt+No4ZPO7o4KarGwUDI+tRc+c0YTrtnztwP1ypXW0zg60DIp/jQbzYb7tSeKVF0+IZCmsCpmRo4pd5JBpKHX4f2osjjJTpg/YduKRIzK4+cAAAAASUVORK5CYII=
""")

PLUG_SUM = base64.decode("""
R0lGODdhCgAKAOYAAAAAAAArqk0sJVQ/SVVASVVVqkBsADlvPDR5pkF6pgCAgECAQECAgICAgEaMAF+NAN+NAEqOtWKQO0OSRU2SRTyYnTOZM2aZM12bXWubA4ybnWieXeigOLyiADmjSdmjOUmlSACnclqnSFyoRzqpOmWpcrepAACq/zCq3VWqqlWq/6qq/9GqAGOrOQCs4Eau6W63n3+864C864+9FEC/QIC/QJa/FLO/v7XAnZ3E4kvJ7V7J7ZrLVqDLVpnMM4DNLJrNS1XP75TPK4zSRmHT/2jT/5XTRsXU4nrVdY7YRY7Y+8fZ5U/a+pvaRZ/ac2Hb98jb6Vnc/8fc6n7e/93x+P/48AD//4D//+H//////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAkAAFoALAAAAAAKAAoAAAc/gFqCUoJQgodaR4JLiFpTSlFFMS+IQUxPOi4oiDNCGRktDohARgcSIxOIPE0PBiIYjU4wFSWNghEJtoIDAoiBACH5BAkAAFoALAIAAAAGAAoAAAc4gFpSWlpQhEeES1pTSlFFMS9BTE86LigzQhkZLQ5ARgcSIxM8TQ8GIhhaTjAVJYRaEQmvWgMChIEAIfkECQAAWgAsAgAAAAYACgAABziAWlJaWlCER4RLWlNKUUUxL0FMTzouKDNCGRktDkBGBxIjEzxNDwYiGFpOMBUlhFoRCa9aAwKEgQAh+QQJAABaACwCAAAABgAKAAAHOIBaUlpaUIRHhEtaU0pRRTEvQUxPOi4oM0IZGS0OQEYHEiMTPE0PBiIYWk4wFSWEWhEJr1oDAoSBACH5BAkAAFoALAIAAAAGAAoAAAc4gFpSWlpQhEeES1pTSlFFMS9BTE86LigzQhkZLQ5ARgcSIxM8TQ8GIhhaTjAVJYRaEQmvWgMChIEAIfkECQAAWgAsAgAAAAYACgAABziAWlJaWlCER4RLWlNKUUUxL0FMTzouKDNCGRktDkBGBxIjEzxNDwYiGFpOMBUlhFoRCa9aAwKEgQAh+QQJAABaACwCAAAABgAKAAAHOIBaUlpaUIRHhEtaU0pRRTEvQUxPOi4oM0IZGS0OQEYHEiMTPE0PBiIYWk4wFSWEWhEJr1oDAoSBACH5BAkAAFoALAIAAAAGAAoAAAc4gFpSWlpQhEeES1pTSlFFMS9BTE82LigzQhkZLQ5ARgcSIxM8TQ8GIhhaTjAVJYRaEQmvWgMChIEAIfkECQAAWgAsAgAAAAYACgAABziAWlJaWlCER4RLWlNKUUUxL0FMTzouKDNCGRktDkBGBxIjEzxNDwYiGFpOMBUlhFoRCa9aAwKEgQAh+QQJAABaACwCAAAABgAKAAAHOIBaUlpaUIRHhEtaU0pRRTEvQUxPOi4oM0IZGS0OQEYHEiMTPE0PBiIYWk4wFSWEWhEJr1oDAoSBACH5BAkAAFoALAIAAAAGAAoAAAc4gFpSWlpQhEeES1pTSlFEMi9BTE87Lig2PyYdJA9AQxwfIBQ9SSwQHhtaSDgaIYRaEQivWgQChIEAIfkECQAAWgAsAgAAAAYACgAABziAWlJaWlCER4RLWlNKUUQyL0FMTzsuKDY/Jh0kD0BDHB8gFD1JLBAeG1pIOBohhFoRCK9aBAKEgQAh+QQJAABaACwCAAAABgAKAAAHOIBaUlpaUIRHhEtaU0pRRDIvQUxPOy4oNj8mHSQPQEMcHyAUPUksEB4bWkg4GiGEWhEIr1oEAoSBACH5BAkAAFoALAIAAAAGAAoAAAc4gFpSWlpQhEeES1pTSlFEMi9BTE87Lig2PyYdJA9AQxwfIBQ9SSwQHhtaSDgaIYRaEQivWgQChIEAIfkECQAAWgAsAgAAAAYACgAABziAWlJaWlCER4RLWlNKUUQyL0FMTzsuKDY/Jh0kD0BDHB8gFD1JLBAeG1pIOBohhFoRCK9aBAKEgQAh+QQJAABaACwCAAAABgAKAAAHOIBaUlpaUIRHhEtaU0pRRDIvQUxPOy4oNj8mHSQPQEMcHyAUPUksEB4bWkg4GiGEWhEIr1oEAoSBACH5BAkAAFoALAIAAAAGAAoAAAc4gFpSWlpQhEeES1pTSlFEMi9BTE87Lig2PyYdJA9AQxwfIBQ9SSwQHhtaSDgaIYRaEQivWgQChIEAIfkECQAAWgAsAgAAAAYACgAABziAWlJaWlCER4RLWlNKUUQyL0FMTzsuKDY/Jh0kD0BDHB8gFD1JLBAeG1pIOBohhFoRCK9aBAKEgQAh+QQJAABaACwCAAAABgAKAAAHOIBaUlpaUIRHhEtaU0pRRDIvQUxPOy4oNj8mHSQPQEMcHyAUPUksEB4bWkg4GiGEWhEIr1oEAoSBACH5BAkAAFoALAIAAAAGAAoAAAc4gFpSWlpQhEeES1pTSlFEMi9BTE87Lig2PyYdJA9AQxwfIBQ9SSwQHhtaSDgaIYRaEQivWgQChIEAOw==
""")

def format_energy(wh):
    """Format energy value with appropriate unit (kWh, MWh, or GWh)."""
    if wh >= 1000000000:  # >= 1 GWh
        return humanize.float("#,###.##", wh / 1000000000) + " GWh"
    elif wh >= 1000000:  # >= 1 MWh
        return humanize.float("#,###.##", wh / 1000000) + " MWh"
    else:  # kWh
        return humanize.float("#,###.##", wh / 1000) + " kWh"

def create_today_frame(title, production):
    """Create today's frame with production only (no consumption line)."""
    return render.Stack(
        children = [
            render.Column(
                main_align = "space_evenly",
                expanded = True,
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text(title),
                        ],
                    ),
                    render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Image(src = SUN_SUM),
                            render.Text(
                                content = " " + format_energy(production),
                                font = "5x8",
                                color = GREEN,
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

def create_summary_frame(title, production, consumption):
    """Create a summary frame with title and energy values."""
    return render.Stack(
        children = [
            render.Column(
                main_align = "space_evenly",
                expanded = True,
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text(title),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "center",
                                children = [
                                    render.Image(src = SUN_SUM),
                                    render.Image(src = PLUG_SUM),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "end",
                                children = [
                                    render.Text(
                                        content = " " + format_energy(production),
                                        font = "5x8",
                                        color = GREEN,
                                    ),
                                    render.Text(
                                        content = " " + format_energy(consumption),
                                        font = "5x8",
                                        color = RED,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

def main(config):
    proxy_url = config.str("proxy_url", "")
    api_key = config.str("api_key", "")
    
    frames = []
    
    # Get energy data from proxy
    if proxy_url and api_key:
        # Clean up the proxy URL
        proxy_url = proxy_url.strip()
        proxy_url = proxy_url.rstrip("/")
        
        # Ensure it has https://
        if not proxy_url.startswith("http://") and not proxy_url.startswith("https://"):
            proxy_url = "https://" + proxy_url
        
        # Build the full URL
        full_url = proxy_url + "/api/solar"
        
        print("Calling:", full_url)
        
        # Call the proxy service
        rep = http.get(
            full_url,
            headers = {"X-API-Key": api_key},
            ttl_seconds = CACHE_TTL,
        )
        
        if rep.status_code != 200:
            return render.Root(render.Box(render.WrappedText("Proxy Error: " + str(rep.status_code), color = RED)))
        
        data = rep.json()
        
        if "error" in data:
            return render.Root(render.Box(render.WrappedText("Error: " + data["error"], color = RED)))
        
        periods = data.get("periods", {})
        
        # Day - production only (cleaner design)
        day_data = periods.get("day", {})
        frames.append(create_today_frame(
            "Energy Today",
            day_data.get("production_wh", 0)
        ))
        
        # Week - both production and consumption
        week_data = periods.get("week", {})
        frames.append(create_summary_frame(
            "Energy Week",
            week_data.get("production_wh", 0),
            week_data.get("consumption_wh", 0)
        ))
        
        # Month - both production and consumption
        month_data = periods.get("month", {})
        frames.append(create_summary_frame(
            "Energy Month",
            month_data.get("production_wh", 0),
            month_data.get("consumption_wh", 0)
        ))
        
        # Year - both production and consumption
        year_data = periods.get("year", {})
        frames.append(create_summary_frame(
            "Energy Year",
            year_data.get("production_wh", 0),
            year_data.get("consumption_wh", 0)
        ))
        
        # Lifetime - both production and consumption
        lifetime_data = periods.get("lifetime", {})
        frames.append(create_summary_frame(
            "Energy Life",
            lifetime_data.get("production_wh", 0),
            lifetime_data.get("consumption_wh", 0)
        ))
    else:
        # Demo data if no credentials
        frames.append(create_today_frame("Energy Today", 6282))
        frames.append(create_summary_frame("Energy Week", 43974, 21987))
        frames.append(create_summary_frame("Energy Month", 188460, 94230))
        frames.append(create_summary_frame("Energy Year", 2261520, 1130760))
        frames.append(create_summary_frame("Energy Life", 11307600, 5653800))
    
    # Return animation with frames
    return render.Root(
        delay = 3000,  # 3 seconds per frame
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "proxy_url",
                name = "Proxy URL",
                desc = "URL of your Enphase proxy service (e.g., https://your-app.onrender.com)",
                icon = "globe",
            ),
            schema.Text(
                id = "api_key",
                name = "Proxy API Key",
                desc = "API key for authenticating with your proxy service",
                icon = "key",
            ),
        ],
    )
