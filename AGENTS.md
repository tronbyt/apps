# AGENTS.md

### 1. Creating a New App
- Use the command:
  ```sh
  pixlet create apps/<appname>
  ```
  This will scaffold a new app directly in the `apps` folder. Replace `<appname>` with your desired app name.

### 2. Ensuring Code Quality
- Use the following commands to maintain high code quality:
  - `pixlet lint` — Checks your app for common issues and style problems.
  - `pixlet check` — Validates your app for correctness and best practices.
  - `pixlet format` — Automatically formats your code for consistency.

### 3. Previewing Your App
- Before publishing, generate a preview image:
  ```sh
  pixlet render apps/<appname>/<app_name>.star
  ```
  This helps reviewers and users see what your app looks like. Replace `<appname>` and `<app_name>` as appropriate.

### 4. Starlark Coding Guidelines
- **Do not use `try/catch`**: Starlark does not support exception handling with try/catch. Use conditional checks and error handling patterns supported by Starlark.

### 5. Reference Documentation
- For available modules and APIs, consult:
  - [Tidbyt Modules Reference](https://tidbyt.dev/docs/reference/modules)
  - [Tidbyt Widgets Reference](https://tidbyt.dev/docs/reference/widgets)

These resources provide details on supported functions, widgets, and best practices for app development.


### 6. Running a Local Server
- Use `pixlet serve` to run a local development server and preview your app live as you make changes. This is useful for rapid iteration and testing.
  ```sh
  pixlet serve apps/<appname>/<app_name>.star
  ```
  You can then view your app in a browser or compatible device.

### 7. Using a Config File for Longer Configurations
- For apps with longer or more complex configurations, use a config file to manage settings. This keeps your code clean and makes it easier to update or share configurations.
  - Reference your config file in your app as needed, following Pixlet and Starlark best practices.


### 8. Skipping Rendering When Not Needed
- In your main app function, you can return an empty array (`return []`) to skip rendering for the current cycle. This is useful if your app should only display content when it's relevant or useful, such as hiding the screen when a device is offline or data is unavailable.

By following these steps, you can ensure your app is well-structured, high-quality, and ready for review or publication. Happy coding!
