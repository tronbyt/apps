load("encoding/json.star", "json")
load("re.star", "re")

def parse_progress(body):
    # Goodreads' redesigned challenge page embeds progress in its bootstrap data.
    challenge_data = re.findall(r"window\.urcData\s*=\s*(\{[\s\S]*?\})\s*;", body)
    if challenge_data:
        data = json.decode(challenge_data[0].split("=", 1)[1].strip().rstrip(";"))
        progress = str(data.get("readingProgress", ""))
        goal = str(data.get("readingGoal", ""))
        if not re.findall(r"^[0-9]+$", progress) or not re.findall(r"^[0-9]+$", goal):
            fail("Invalid Goodreads reading progress or goal")
        return (progress, goal)

    progress_div = re.findall(r"<div class='progressText'>([\s\S]*?)</div>", body)
    if not progress_div:
        fail("No challenge progress found")
    progress_nums = re.findall(r"\d+", progress_div[0])
    if len(progress_nums) < 2:
        fail("Invalid Goodreads reading progress or goal")
    return (progress_nums[0], progress_nums[1])
