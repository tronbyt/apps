load("time.star", "time")

def parse_ts(ts):
    base = ts.split(".")[0]
    return time.parse_time(base if base.endswith("Z") else base + "Z")

def truncate(name, max_len = 12):
    return name[:max_len] + "..." if len(name) > max_len else name
