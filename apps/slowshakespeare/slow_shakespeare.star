"""
Applet: Slow Shakespeare
Author: Matt Milligan
Summary: Learn sonnets daily
Description: Learn a Shakespeare sonnet one line at a time.
    One new line per day, 14 days per sonnet.
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Shakespeare's Sonnets
SONNETS = {
    "1": [
        "From fairest creatures we desire increase,",
        "That thereby beauty's rose might never die,",
        "But as the riper should by time decrease,",
        "His tender heir might bear his memory:",
        "But thou, contracted to thine own bright eyes,",
        "Feed'st thy light's flame with self-substantial fuel,",
        "Making a famine where abundance lies,",
        "Thyself thy foe, to thy sweet self too cruel.",
        "Thou that art now the world's fresh ornament",
        "And only herald to the gaudy spring,",
        "Within thine own bud buriest thy content",
        "And, tender churl, makest waste in niggarding.",
        "Pity the world, or else this glutton be,",
        "To eat the world's due, by the grave and thee.",
    ],
    "18": [
        "Shall I compare thee to a summer's day?",
        "Thou art more lovely and more temperate:",
        "Rough winds do shake the darling buds of May,",
        "And summer's lease hath all too short a date:",
        "Sometime too hot the eye of heaven shines,",
        "And often is his gold complexion dimm'd;",
        "And every fair from fair sometime declines,",
        "By chance, or nature's changing course untrimm'd;",
        "But thy eternal summer shall not fade,",
        "Nor lose possession of that fair thou ow'st;",
        "Nor shall death brag thou wander'st in his shade,",
        "When in eternal lines to time thou grow'st:",
        "So long as men can breathe, or eyes can see,",
        "So long lives this, and this gives life to thee.",
    ],
    "29": [
        "When, in disgrace with fortune and men's eyes,",
        "I all alone beweep my outcast state,",
        "And trouble deaf heaven with my bootless cries,",
        "And look upon myself and curse my fate,",
        "Wishing me like to one more rich in hope,",
        "Featured like him, like him with friends possessed,",
        "Desiring this man's art and that man's scope,",
        "With what I most enjoy contented least;",
        "Yet in these thoughts myself almost despising,",
        "Haply I think on thee, and then my state,",
        "Like to the lark at break of day arising",
        "From sullen earth, sings hymns at heaven's gate;",
        "For thy sweet love remembered such wealth brings",
        "That then I scorn to change my state with kings.",
    ],
    "30": [
        "When to the sessions of sweet silent thought",
        "I summon up remembrance of things past,",
        "I sigh the lack of many a thing I sought,",
        "And with old woes new wail my dear time's waste:",
        "Then can I drown an eye, unused to flow,",
        "For precious friends hid in death's dateless night,",
        "And weep afresh love's long since cancell'd woe,",
        "And moan the expense of many a vanish'd sight:",
        "Then can I grieve at grievances foregone,",
        "And heavily from woe to woe tell o'er",
        "The sad account of fore-bemoaned moan,",
        "Which I new pay as if not paid before.",
        "But if the while I think on thee, dear friend,",
        "All losses are restor'd and sorrows end.",
    ],
    "55": [
        "Not marble, nor the gilded monuments",
        "Of princes, shall outlive this powerful rhyme;",
        "But you shall shine more bright in these contents",
        "Than unswept stone, besmear'd with sluttish time.",
        "When wasteful war shall statues overturn,",
        "And broils root out the work of masonry,",
        "Nor Mars his sword, nor war's quick fire shall burn",
        "The living record of your memory.",
        "'Gainst death, and all oblivious enmity",
        "Shall you pace forth; your praise shall still find room",
        "Even in the eyes of all posterity",
        "That wear this world out to the ending doom.",
        "So, till the judgment that yourself arise,",
        "You live in this, and dwell in lovers' eyes.",
    ],
    "73": [
        "That time of year thou mayst in me behold",
        "When yellow leaves, or none, or few, do hang",
        "Upon those boughs which shake against the cold,",
        "Bare ruin'd choirs, where late the sweet birds sang.",
        "In me thou see'st the twilight of such day",
        "As after sunset fadeth in the west,",
        "Which by and by black night doth take away,",
        "Death's second self, that seals up all in rest.",
        "In me thou see'st the glowing of such fire",
        "That on the ashes of his youth doth lie,",
        "As the death-bed whereon it must expire,",
        "Consum'd with that which it was nourish'd by.",
        "This thou perceiv'st, which makes thy love more strong,",
        "To love that well which thou must leave ere long.",
    ],
    "104": [
        "To me, fair friend, you never can be old,",
        "For as you were when first your eye I ey'd,",
        "Such seems your beauty still. Three winters cold,",
        "Have from the forests shook three summers' pride,",
        "Three beauteous springs to yellow autumn turn'd,",
        "In process of the seasons have I seen,",
        "Three April perfumes in three hot Junes burn'd,",
        "Since first I saw you fresh, which yet are green.",
        "Ah! yet doth beauty like a dial-hand,",
        "Steal from his figure, and no pace perceiv'd;",
        "So your sweet hue, which methinks still doth stand,",
        "Hath motion, and mine eye may be deceiv'd:",
        "For fear of which, hear this thou age unbred:",
        "Ere you were born was beauty's summer dead.",
    ],
    "116": [
        "Let me not to the marriage of true minds",
        "Admit impediments. Love is not love",
        "Which alters when it alteration finds,",
        "Or bends with the remover to remove.",
        "O no, it is an ever-fixed mark",
        "That looks on tempests and is never shaken;",
        "It is the star to every wand'ring bark,",
        "Whose worth's unknown, although his height be taken.",
        "Love's not Time's fool, though rosy lips and cheeks",
        "Within his bending sickle's compass come;",
        "Love alters not with his brief hours and weeks,",
        "But bears it out even to the edge of doom.",
        "If this be error and upon me proved,",
        "I never writ, nor no man ever loved.",
    ],
    "130": [
        "My mistress' eyes are nothing like the sun;",
        "Coral is far more red than her lips' red;",
        "If snow be white, why then her breasts are dun;",
        "If hairs be wires, black wires grow on her head.",
        "I have seen roses damasked, red and white,",
        "But no such roses see I in her cheeks;",
        "And in some perfumes is there more delight",
        "Than in the breath that from my mistress reeks.",
        "I love to hear her speak, yet well I know",
        "That music hath a far more pleasing sound;",
        "I grant I never saw a goddess go;",
        "My mistress, when she walks, treads on the ground.",
        "And yet, by heaven, I think my love as rare",
        "As any she belied with false compare.",
    ],
    "138": [
        "When my love swears that she is made of truth",
        "I do believe her, though I know she lies,",
        "That she might think me some untutor'd youth,",
        "Unlearned in the world's false subtleties.",
        "Thus vainly thinking that she thinks me young,",
        "Although she knows my days are past the best,",
        "Simply I credit her false speaking tongue:",
        "On both sides thus is simple truth suppress'd.",
        "But wherefore says she not she is unjust?",
        "And wherefore say not I that I am old?",
        "O, love's best habit is in seeming trust,",
        "And age in love loves not to have years told:",
        "Therefore I lie with her and she with me,",
        "And in our faults by lies we flatter'd be.",
    ],
}

# Default text color
DEFAULT_COLOR = "#8FBF8F"  # Salad Days

# Sonnet order for auto-advance
SONNET_ORDER = ["1", "18", "29", "30", "55", "73", "104", "116", "130", "138"]

def main(config):
    """Render today's sonnet line for the Tidbyt display."""
    sonnet_id = config.get("sonnet", "18")
    text_color = config.get("color", DEFAULT_COLOR)
    show_line_number = config.bool("show_line_number", False)

    now = time.now()

    # Get start date from config, default to today
    start_date_str = config.get("start_date")
    if start_date_str:
        start_date = time.parse_time(start_date_str)
    else:
        start_date = now

    # Calculate total days since start
    # Use Unix timestamps for reliable day calculation across timezones
    now_unix = now.unix
    start_unix = start_date.unix
    total_days = int((now_unix - start_unix) / 86400)  # 86400 seconds per day

    # No future dates
    if total_days < 0:
        total_days = 0

    # Each sonnet takes 14 days, figure out which sonnet and which day within it
    if sonnet_id in SONNET_ORDER:
        sonnet_index = SONNET_ORDER.index(sonnet_id)
    else:
        sonnet_index = 1
    sonnets_completed = total_days // 14
    day_within_sonnet = total_days % 14

    # Advance to the next sonnet(s) based on time passed
    current_sonnet_index = sonnet_index + sonnets_completed

    # Wrap around to beginning if we've gone through all sonnets
    current_sonnet_index = current_sonnet_index % len(SONNET_ORDER)

    current_sonnet_id = SONNET_ORDER[current_sonnet_index]
    lines = SONNETS.get(current_sonnet_id, SONNETS["18"])

    lines_learned = day_within_sonnet + 1

    # Clamp to number of lines
    if lines_learned > len(lines):
        lines_learned = len(lines)
    if lines_learned < 1:
        lines_learned = 1

    # The newest line (today's focus)
    newest_line_index = lines_learned - 1

    static_children = [
        render.Padding(
            pad = (2, 2, 2, 2),
            child = render.WrappedText(
                content = lines[newest_line_index],
                font = "tom-thumb",
                color = text_color,
                align = "left",
            ),
        ),
    ]

    if show_line_number:
        static_children.append(
            render.Column(
                expanded = True,
                main_align = "end",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "end",
                        children = [
                            render.Padding(
                                pad = (0, 0, 2, 2),
                                child = render.Text(
                                    content = str(newest_line_index + 1),
                                    font = "tom-thumb",
                                    color = text_color,
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        )

    return render.Root(
        child = render.Stack(
            children = static_children,
        ),
    )

def get_schema():
    """Return the Tidbyt configuration schema."""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "sonnet",
                name = "Sonnet",
                desc = "Choose a sonnet to memorize",
                icon = "book",
                default = "18",
                options = [
                    schema.Option(
                        display = "1: From fairest creatures...",
                        value = "1",
                    ),
                    schema.Option(
                        display = "18: Shall I compare thee...",
                        value = "18",
                    ),
                    schema.Option(
                        display = "29: When in disgrace...",
                        value = "29",
                    ),
                    schema.Option(
                        display = "30: When to the sessions...",
                        value = "30",
                    ),
                    schema.Option(
                        display = "55: Not marble nor...",
                        value = "55",
                    ),
                    schema.Option(
                        display = "73: That time of year...",
                        value = "73",
                    ),
                    schema.Option(
                        display = "104: To me, fair friend...",
                        value = "104",
                    ),
                    schema.Option(
                        display = "116: Let me not to the marriage...",
                        value = "116",
                    ),
                    schema.Option(
                        display = "130: My mistress' eyes...",
                        value = "130",
                    ),
                    schema.Option(
                        display = "138: When my love swears...",
                        value = "138",
                    ),
                ],
            ),
            schema.DateTime(
                id = "start_date",
                name = "Started",
                desc = "Sync with a friend by matching start dates",
                icon = "calendar",
            ),
            schema.Dropdown(
                id = "color",
                name = "Color",
                desc = "Text color",
                icon = "palette",
                default = "#8FBF8F",
                options = [
                    schema.Option(
                        display = "Salad Days",
                        value = "#8FBF8F",
                    ),
                    schema.Option(
                        display = "Milk of Kindness",
                        value = "#B5A99A",
                    ),
                    schema.Option(
                        display = "Midsummer Night",
                        value = "#7BA3D4",
                    ),
                    schema.Option(
                        display = "All That Glisters",
                        value = "#D4B86A",
                    ),
                    schema.Option(
                        display = "Damask Rose",
                        value = "#D4856E",
                    ),
                ],
            ),
            schema.Toggle(
                id = "show_line_number",
                name = "Line numbers",
                desc = "Show line number in corner",
                icon = "hashtag",
                default = False,
            ),
        ],
    )
