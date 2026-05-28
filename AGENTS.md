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

## 8. Reference Documentation
- [Modules](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/modules.md) | [Widgets](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/widgets.md) | [Animation](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/animation.md) | [Schema](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/schema/schema.md) | [Filters](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/filters.md)
- **Fonts**: Run `pixlet community list-fonts` or view the [Fonts Reference](https://raw.githubusercontent.com/tronbyt/pixlet/refs/heads/main/docs/fonts.md).
- **Icons**: Run `pixlet community list-icons`.
```
