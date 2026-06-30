def truncate(name, max_len = 12):
    return name[:max_len] + "..." if len(name) > max_len else name

def round_up_y_max(max_val):
    if max_val <= 0:
        return 1
    if max_val < 100:
        return max_val
    if max_val < 1000:
        return ((max_val + 9) // 10) * 10
    if max_val < 10000:
        return ((max_val + 99) // 100) * 100
    return ((max_val + 999) // 1000) * 1000
