# DailyKanji

A little Japanese. A daily discovery. One character at a time.

DailyKanji turns your Tidbyt or compatible Tronbyt display into a colorful little study companion.

A large kanji character appears alongside its English meaning and romanized readings, giving you something to recognize, revisit, and remember throughout the day. Choose a difficulty level that suits your learning, then let a small daily encounter with Japanese become part of your surroundings.

No flashcard marathon required—just a little curiosity every time you glance at your display.

## Display Previews

DailyKanji supports three display formats, placing the character on the left and scrolling its meaning and readings on the right.

### Standard Display — 64 × 32

A compact study card for standard-resolution displays, with a prominent yellow character and three color-coded text rows.

![DailyKanji on a standard 64 × 32 display](dailykanji.webp)

### Wide 2× Display — 128 × 64

The higher-resolution wide version uses a larger character image and a larger text font, giving the meaning and readings more room.

![DailyKanji on a wide 128 × 64 display](dailykanji@2x.webp)

### Square Display — 64 × 64

The square layout vertically centers the text block and adjusts the character image’s placement for the taller canvas.

![DailyKanji on a square 64 × 64 display](dailykanji@64x64.webp)

## Features

- Date-based character selection — Features a character selected from the date and your chosen difficulty level.
- Five difficulty settings — Choose Beginner, Elementary, Intermediate, Advanced, or Expert.
- Cumulative character pools — Higher settings include the app’s easier-level characters as well.
- Large kanji presentation — A yellow character anchors the left side of the display.
- English meaning — See the meaning returned by the Kanji Alive API.
- Romanized readings — View onyomi and kunyomi readings in Latin letters.
- Color-coded text rows — Distinguish meaning and readings at a glance.
- Scrolling details — Longer text moves through the available space.
- Adjustable scrolling speed — Choose slow, medium, or fast playback.
- Two-hour caching — Reuses character details and image data between refreshes.
- Consistent sample fallback — Shows a complete sample entry if no API key is supplied or a detail lookup fails.
- Three display formats — Support for standard 64 × 32, wide 128 × 64, and square 64 × 64 panels.

## Reading the Display

The character appears on the left. Three scrolling rows appear on the right:

| Row | Color | Content |
| --- | --- | --- |
| Top | Light blue | English meaning |
| Middle | Amber | Onyomi in romaji |
| Bottom | Orange | Kunyomi in romaji |

The readings are shown in romaji—Latin-letter transliterations—not as audio or kana.

Missing readings and values returned as “n/a” are left blank.

## Choose Your Learning Level

The app groups its included characters into five difficulty pools, labeled using JLPT levels.

| Setting | Included pools |
| --- | --- |
| Beginner | N5 |
| Elementary | N5 and N4 |
| Intermediate | N5 through N3 |
| Advanced | N5 through N2 |
| Expert | N5 through N1 |

The selected setting is a maximum difficulty, not an exclusive filter.

For example, Expert can still show a character from the Beginner pool. That makes room for familiar characters as well as more challenging ones.

These are the app’s curated lists, not a complete exam syllabus or a guarantee of official JLPT classification.

## A Daily Character, Not a Two-Hour Shuffle

The app chooses a character using the date and the selected difficulty level.

Under unchanged settings, the same date produces the same selection. Users with matching settings can therefore receive the same daily character.

The two-hour cache serves a different purpose: it limits how often character information and image data need to be fetched.

A cache refresh during the same day normally selects the same character again. It does not intentionally advance to another character every two hours.

### A Few Timing Details

- Consecutive days can select the same character.
- Selection is not a no-repeat tour through the character pool.
- The selection code uses the runtime date without an explicit user-time-zone conversion.
- A cached entry can remain visible across a date change until the cache refreshes.
- Replaying an existing rendered animation does not perform a new lookup.

## Setup

DailyKanji uses Kanji Alive through RapidAPI for character meanings and readings.

For normal operation, you’ll need an API key with access to the appropriate API.

1. Create or sign in to your RapidAPI account.
2. Open the Kanji Alive API page:
   [Kanji Alive on RapidAPI](https://rapidapi.com/KanjiAlive/api/learn-to-read-and-write-japanese-kanji/playground)
3. Follow the provider’s access and subscription requirements.
4. Copy your RapidAPI application key.
5. Add DailyKanji to your display.
6. Enter the key in “API Key.”
7. Choose your “Difficulty Level.”
8. Select your preferred “Scroll Speed.”
9. Save your settings.

Keep your API key private. Do not include it in public screenshots or repository commits.

Check the provider’s current pricing, request limits, and access terms before using the service.

## What Happens Without a Working API Lookup?

If no key is supplied, or the character-details request fails, the app uses a fixed sample entry:

- Character: 辛
- English meaning: pungent, hard, spicy
- Onyomi: shin
- Kunyomi: kara, karai, karasa

The fallback keeps the character, meaning, and readings consistent with one another.

It is not a rotating offline collection. If you repeatedly see this sample, check your API key and provider access.

The current display does not explicitly label the entry as fallback data.

A fallback entry is cached for two hours, so correcting your API settings may not immediately replace an existing cached sample.

## Network Requests and Caching

DailyKanji uses two external services:

- Kanji Alive through RapidAPI for meanings and readings.
- Imgix’s text-rendering endpoint to generate the character image.

Character details and image bytes are cached separately for two hours, with cache entries organized by difficulty level.

Under normal cache operation, repeated renders can reuse those results rather than fetching them every time.

However:

- Cache retention is not guaranteed.
- Changing difficulty can require a different lookup.
- Additional installations or other uses of your subscription may add requests.
- The app does not track your monthly API allowance.
- The character image still requires network access when it is not cached, even when sample details are used.

This is not a fully offline app.

## Available Settings

| Setting | What it does |
| --- | --- |
| API Key | Supplies your private RapidAPI key for Kanji Alive. |
| Difficulty Level | Sets the most advanced included character pool. Defaults to Beginner. |
| Scroll Speed | Selects slow, medium, or fast scrolling. Defaults to Medium. |

## Make It Part of Your Routine

DailyKanji works best as a small companion to your learning, not a replacement for it.

Try taking a moment to:

- Recognize the character before reading its meaning.
- Say the displayed readings aloud.
- Look up a word that uses the character.
- Write it down in a notebook.
- Notice whether it appears in something you read later.

A few familiar pixels can become a useful reminder to keep exploring.

## Notes

- Character selection comes from the app’s bundled lists.
- Meanings and readings depend on the API response.
- The app does not display example vocabulary, stroke order, or pronunciation audio.
- Readings are not a guide to which pronunciation applies in every word.
- The current layout uses fixed text colors and a yellow character image.
- A failed detail lookup can display the sample without an explicit warning.
- External service availability affects operation.

---

A small daily encounter with a beautifully complex language.

Created by Robert Ison.
