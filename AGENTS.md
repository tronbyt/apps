# AGENTS.md

This repository contains Pixlet apps in the `apps/` directory.

## 1. Creating a New App
Scaffold a new app: `pixlet create apps/<appname>`

## 2. Code Quality
- `pixlet lint`: Checks for common issues and style problems.
- `pixlet check`: Validates correctness and best practices.
- `pixlet format`: Auto-formats code for consistency.

## 3. Local Development Server
Run a live-reloading local server for rapid iteration: `pixlet serve apps/<appname>/<app_name>.star`.

## 4. Previewing & Rendering
Generate a preview image before publishing:
```sh
pixlet render -z 9 apps/<appname>/<app_name>.star
# For 2x support preview:
pixlet render -2 -z 9 apps/<appname>/<app_name>.star
```
Screenshot paths will be `apps/<appname>/<appname>.webp` and `apps/<appname>/<appname>@2x.webp`.

## 5. Starlark Guidelines
- **No `try/catch`**: Starlark lacks exception handling. Use conditional checks instead.
- **Skipping Rendering**: Return an empty array (`return []`) in your main function to skip rendering for the current cycle (e.g., when data is unavailable).
- **Loading Local Files:** Load local assets directly into global variables using the `file` target. For example, this loads `apps/<appname>/images/example.png`:
  ```starlark
  load("images/example.png", EXAMPLE_IMAGE = "file")
  ```

## 6. Configurations
Manage complex settings with a config file/schema. Pass configuration arguments via the CLI during development:
```sh
pixlet render apps/<appname>/<app_name>.star key=value
```

- For sensitive values like API keys or passwords, schema definitions should use `secret = True`.
- For boolean options (from schema.Toggle), values should be retrieved using `config.bool("key")` instead of `config.get("key")`.

## 7. 2x Rendering Support
- 2x apps render at 128x64 instead of the standard 64x32.
- Check the `canvas` module: `canvas.size()` returns `(width, height)`; `canvas.width()`, `canvas.height()`, `canvas.is2x()`.
- **Common patterns:**
  ```starlark
  WIDTH, HEIGHT = canvas.size()
  SCALE = 2 if canvas.is2x() else 1
  ```
- Multiply/divide sizes by `SCALE` (use `//` or convert to `int`; floats are rejected).
- Default 1x font is `tb-8`; default 2x font is `terminus-16`.
- **Animations:** If using `render.Marquee`, halve the delay for 2x to maintain scroll speed. If halving the delay speeds up embedded `render.Image` animations, use the image's `hold_frames` parameter to slow it back down.

## 8. Square (64x64) Panel Support
Square panels render at **64x64**. They are a different canvas *shape*, not a
higher resolution, so `canvas.is2x()` is **false** on them.

There are three real canvases: `64x32` (classic), `128x64` (2x, `is2x()` true)
and `64x64` (square, `is2x()` false).

- **Tell panels apart by shape, never by size:**
  ```starlark
  WIDTH, HEIGHT = canvas.size()

  def is_square():
      w, h = canvas.size()
      return h == w
  ```
  Do **not** test `HEIGHT == 64`: the 128x64 wide panel is also 64 tall. Do not
  use heuristics on the aspect ratio either -- `h == w` is the definition.
- **Declare the capability in `manifest.yaml`:**
  ```yaml
  supports64x64: true
  ```
  This is what puts the `64x64` badge on the app in the app store and lets
  users filter for apps their display can show. CI fails an app that adapts its
  layout for square panels without declaring the flag, so add it in the same
  change as the layout work.
- **Preview:**
  ```sh
  pixlet render -w 64 -t 64 -z 9 apps/<appname>/<app_name>.star -o apps/<appname>/<appname>@64x64.webp
  ```
  The `@64x64.webp` screenshot is optional. Unlike `@2x.webp` its presence does
  not imply the capability -- a screenshot shows a preview exists, not that the
  author checked the app on a square panel. `supports64x64` stays a manifest
  assertion.
- A square panel has twice the vertical room of a classic panel and the same
  width, so the usual port is to stack what the 64x32 layout puts side by side,
  or to show more rows of the same content.

## 9. Reference Documentation
- [Modules](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/modules.md) | [Widgets](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/widgets.md) | [Animation](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/animation.md) | [Schema](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/schema/schema.md) | [Filters](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/filters.md)
- **Fonts**: Run `pixlet community list-fonts` or view the [Fonts Reference](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/fonts.md).
- **Icons**: Run `pixlet community list-icons`.
```
