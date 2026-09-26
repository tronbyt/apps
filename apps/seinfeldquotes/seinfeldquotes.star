"""
Applet: SeinfeldQuotes
Summary: Random quote from Seinfeld
Description: Displays a random quote from the hit sitcom, Seinfeld.
Author: ndlybarger
"""

### Special thanks to Marc ten Bosch for lobster facts code template

load("images/the_icon.png", THE_ICON_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

THE_ICON = THE_ICON_ASSET.readall()

QUOTES = [
    "What is this obsession people have with books? They put them in their houses — like they’re trophies. What do you need it for after you read it? —Jerry",
    "You know, I got a great idea for a cologne. ‘The Beach’. You spray it on and you smell like you just came home from the beach. —Kramer",
    "I will never understand the bathrooms in this country. Why is it that the doors on the stalls do not come all the way down to the floor? —George",
    "Hey, how come people don’t have dip for dinner? Why is it only a snack, why can’t it be a meal, you know? I don’t understand stuff like that. —Puddy",
    "Why do I always have the feeling that everybody’s doing something better than me on Saturday afternoons? —Jerry",
    "Look, I got a few good years left. If I want a Chip Ahoy, I’m having it. —Morty Seinfeld",
    "Tuesday has no feel. Monday has a feel, Friday has a feel, Sunday has a feel. —Newman",
    "Do you ever get down on your knees and thank God you know me and have access to my dementia? —George",
    "I’m going to save up every rupee. Someday I will get back to America, and when I do, I will exact vengeance on this man. I cannot forget him. He haunts me. He is a very bad man. He is a very, very bad man. —Babu Bhatt",
    "You’re through, Soup Nazi. Pack it up. No more soup for you. Next! —Elaine",
    "You dipped the chip. You took a bite. And you dipped again. That’s like putting your whole mouth right in the dip! From now on, when you take a chip — just take one dip and end it. —Timmy",
    "But out of that, a new holiday was born. A FESTIVUS FOR THE REST-OF-US. —Frank Costanza",
    "Jerry, just remember, it’s not a lie if you believe it. —George",
    "Looking at cleavage is like looking at the sun. You don’t stare at it. It’s too risky. Ya get a sense of it and then you look away. —Jerry",
    "That’s the bra I gave her, she’s wearing it as a top! The woman is walking around in broad daylight with nothing but a bra on. She’s a menace to society. —Elaine",
    "I love a good nap. Sometimes it’s the only thing getting me out of bed in the morning. —George",
    "Moles — freckles’ ugly cousin. —Kramer",
    "You can’t believe this woman. She’s one of those low-talkers. You can’t hear a word she’s saying! You’re always going ‘excuse me?’, ‘what was that?’ —Jerry",
    "Just remember, when you control the mail, you control… information. —Newman",
    "A bra is for ladies. I’m talking about a support undergarment specifically designed for men. —Kramer",
    "I think if one’s going to kill oneself, the least you could do is leave a note — it’s common courtesy. I don’t know, that’s just the way I was brought up. —George",
    "I can’t go to a bad movie by myself. What, am I gonna make sarcastic remarks to strangers? —Jerry",
    "I’d rather be dating the blind. You know you could let the house go. You could let yourself go. A good-looking blind woman doesn’t even know you’re not good enough for her. —George",
    "Can you die from an odor? I mean, like if you were locked in a vomitorium for two weeks, could you actually die from the odor? —Elaine",
    "What evidence is there that cats are so smart, anyway? Huh? What do they do? Because they’re clean? I am sorry. My Uncle Pete showers four times a day and he can’t count to 10. So don’t give me hygiene. —Elaine",
    "She dumped me! She rolled right over me! Said I was a hipster doofus. Am I a hipster doofus? —Kramer",
    "Hey, believe me, baldness will catch on. When the aliens come, who do you think they’re gonna relate to? Who do you think is going to be the first ones getting a tour of the ship? —George",
    "People don’t turn down money! It’s what separates us from the animals. —Jerry",
    "Why is nice bad? What kind of a sick society are we living in when nice is bad? —George",
    "Human, it’s human to be moved by a fragrance. —Kramer",
    "Yada yada yada. —Elaine",
    "George, we’ve had it with you. Understand? We love you like a son, but even parents have limits. —Frank Costanza",
    "Breaking up is like knocking over a Coke machine. You can’t do it in one push; you got to rock it back and forth a few times, and then it goes over. —Jerry",
    "You know, I always wanted to pretend I was an architect. —George",
    "I’m not a lesbian! I hate men, but I’m not a lesbian. —Elaine",
    "Salad! What was I thinking? Women don’t respect salad eaters. —Jerry",
    "You ever dream in 3D? It’s like the bogeyman is coming RIGHT AT YOU. —Kramer",
    "I’ve never assisted in a birth before. It’s really quite disgusting. —George",
    "Maybe the dingo ate your baby! —Elaine",
    "You know the message you’re sending out to the world with sweatpants? You’re telling the world: ‘I give up. I can’t compete in normal society. I’m miserable, so I might as well be comfortable.’ —Jerry",
    "Three squares? You can’t spare three squares? —Elaine",
    "I spend so much time trying to get their clothes off, I never thought of taking mine off. —George",
    "Do you think it’s effeminate for a man to put clothes in a gentle cycle? —Jerry",
    "Oh, understudies are a very shifty bunch. The substitute teachers of the theater world. —Kramer",
    "I don’t think George has ever thought he’s better than anybody. —Elaine",
    "That’s the true spirit of Christmas; people being helped by people other than me. —Jerry",
    "Why does everything have to be ‘us’? Is there no ‘me’ left? Why can’t there be some things just for me? Is that so selfish? —George",
    "I just couldn’t decide if he was really sponge-worthy. —Elaine",
    "He stopped short? That’s my move. I’m gonna kill him! —Frank Costanza",
    "A preemptive breakup. This is an incredible idea. I got nothing to lose. We either break up, which she would do anyway, but at least I go out with some dignity. Completely turn the tables. It’s absolutely brilliant. —George",
    "Jerry, my face is my livelihood, my allure… my twinkle! Everything I have I owe to this face. —Kramer",
    "I don’t even care about cops. I wanna see more garbage men. It’s much more important. All I wanna see are garbage trucks, garbage cans, and garbage men. You’re never gonna stop crime, we should at least be clean. —Jerry",
    "The sea was angry that day, my friends, like an old man trying to send back soup in a deli… —George",
    "It’s the best part. It’s crunchy, it’s explosive, it’s where the muffin breaks free of the pan and sort of does its own thing. I’ll tell you. That’s a million-dollar idea right there. Just sell the tops. —Elaine",
    "Did you know that the original title for War and Peace was War, What Is It Good For? —Jerry",
    "I’m busting, Jerry! I’m busting! —George",
    "Hunger will make people do amazing things. I mean, the proof of that is cannibalism. —Jerry",
    "I’ll go, if I don’t have to talk. —Elaine",
    "I can’t die with dignity. I have no dignity. I want to be the one person who doesn’t die with dignity. I live my whole life in shame. Why should I die with dignity? —George",
    "He took IT out. —Elaine",
    "I love the name ‘Isosceles.’ If I had a kid, I would name him Isosceles. Isosceles Kramer. —Kramer",
    "I guarantee you that Moses was a picker. You wander through the desert for 40 years with that dry air. You telling me you’re not going to have occasion to clean house a little bit? —George",
    "What is it about sleep that makes you so thirsty? Do dreams require liquid? It’s not like I’m running a marathon, I’m just lying there. —Jerry",
    "Boxers! How do you wear these things!! They’re baggin’ up, they’re rising in! And there’s nothing holding me in place! I’m flippin’! I’m floppin’! —Kramer",
    "Yeah, I’m a great quitter. It’s one of the few things I do well. I come from a long line of quitters. My father was a quitter, my grandfather was a quitter. I was raised to give up. —George",
    "What could possess anyone to throw a party? I mean, to have a bunch of strangers treat your house like a hotel room. —Jerry",
    "I’m speechless. I’m without speech. —Elaine",
    "When you look annoyed all the time, people think that you’re busy. —George",
    "Somewhere in this hospital, the anguished squeal of Pigman cries out! —Kramer",
    "Listen carefully. My mother has never laughed. Ever. Not a giggle, not a chuckle, not a tee-hee… never went ‘Ha!’ —George",
    "I don’t know how you guys walk around with those things. —Elaine",
    "Hello, Newman. —Jerry",
    "I don’t think I’ve ever been to an appointment in my life where I wanted the other guy to show up. —George",
    "We don’t know how long this will last. They are a very festive people. —Elaine",
    "Well, you know what they say, you don’t sell the steak, you sell the sizzle. —Kramer",
    "Like I don’t know I’m pathetic. —George",
    "SERENITY NOW! —Frank Costanza",
    "Who goes on vacation without a job? What do you need a break from getting up at eleven? —Jerry",
    "I need the secure packaging of jockeys. My boys need a house. —Kramer",
    "He’s a re-gifter. —Elaine",
    "You’re killing independent George! —George",
    "What’s the deal with lampshades? I mean, if it’s a lamp, why do you want shade? —Jerry",
    "Frolf: Frisbee golf, Jerry. Golf with a Frisbee. This is gonna be my time. Time to taste the fruits and let the juices drip down my chin. I proclaim this: The Summer of George! —George",
    "He’s a close talker. —Elaine",
    "All of a sudden it hit me, I realized what the problem is: I can’t be with someone like me. I hate myself! If anything, I need to get the exact opposite of me. It’s too much. It’s too much, I can’t take it. I can’t take it. —Jerry",
    "The carpet sweeper is the biggest scam perpetrated on the American public since one-hour martinizing. —Kramer",
    "You should’ve seen her face. It was the exact same look my father gave me when I told him I wanted to be a ventriloquist. —George",
    "She has man hands. —Jerry",
    "I want to be the one person who doesn’t die with dignity. —George",
    "Look to the cookie, Elaine! —Jerry",
    "Say you got a big job interview, and you’re a little nervous. Well, throw back a couple shots of Hennigan’s and you’ll be as loose as a goose and ready to roll in no time. And because it’s odorless, why, it will be our little secret. —Kramer",
    "I’m disturbed, I’m depressed, I’m inadequate, I’ve got it all! —George",
    "No one is touching my feet. Between you and me, Elaine, I think I’ve got a foot odor problem. —Frank Costanza",
    "If every instinct you have is wrong, then the opposite would have to be right. —Jerry",
    "I’m much more comfortable criticizing people behind their backs. —George",
    "There’s more to life than making shallow, fairly obvious observations. —Jerry",
    "She’s a sentence finisher. It’s like dating Mad Libs. —Jerry",
    "It’s not fair that people are seated first-come, first-served. It should be based on who’s hungriest. —Elaine",
    "If you want to make a person feel better after they sneeze, you shouldn’t say ‘God bless you.’ You should say, ‘You’re so good looking!’ —Jerry",
    "My dream is to become hopeless. —George",
    "Is it possible that I’m not as attractive as I think I am? —Elaine",
    "I’m out there, Jerry, and I’m lovin’ every minute of it! —Kramer",
    "It’s a pizza place where you make your own pie! We give you the dough, the sauce, the cheese… you pound it, slap it, you flip it up into the air… you put your toppings on and you slide it into the oven! Sounds good, huh? —Kramer",
    "You’re a rabid anti-dentite! Oh, it starts with a few jokes and some slurs. ‘Hey, denty!’ Next thing you know, you’re saying they should have their own schools. —Kramer",
    "They don’t have a decent piece of fruit at the supermarket. The apples are mealy, the oranges are dry. I don’t know what’s going on with the papayas! —Kramer",
    "If everybody knew everybody, we wouldn’t have the problems we have in the world today. Well, you don’t rob somebody if you know their name! —Kramer",
    "See, here, you’re just another apple, but in Japan, you’re an exotic fruit. Like an orange. Which is rare there. —Kramer",
    "Don’t insult me, my friend. Remember who you’re talking to. No one’s a bigger idiot than me. —George",
    "You know, the very fact that you oppose this makes me think I’m on to something. —Jerry",
    "Food and sex. Those are my two passions. —George",
    "I lie every second of the day. My whole life is a sham. —George",
]

def main():
    idx = random.number(0, len(QUOTES) - 1)
    print(random)
    current_fact = QUOTES[idx]

    return render.Root(
        child = render.Padding(
            pad = 1,
            child = render.Marquee(
                height = 30,
                child = render.Column(
                    cross_align = "center",
                    children = [
                        render.Image(src = THE_ICON),
                        render.WrappedText(current_fact, width = 62),
                    ],
                ),
                offset_start = 8,
                offset_end = 0,
                scroll_direction = "vertical",
            ),
        ),
    )
