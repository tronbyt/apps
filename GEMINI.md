# Project Overview

This repository is a community-maintained collection of applications for the Tronbyt (formerly Tidbyt) device. These applications are written in Starlark, a dialect of Python, and utilize the Pixlet framework for development and testing. The repository is a hard fork of the original Tidbyt community repository and is actively maintained by the community.

## Key Technologies

*   **Starlark:** The primary programming language for the applications.
*   **Pixlet:** The command-line tool for developing, running, and testing Tronbyt apps. The recommended version is specified in the `PIXLET_VERSION` file.
*   **YAML:** Used for the application manifests (`manifest.yaml`).

## Project Structure

The repository is organized as follows:

*   `apps/`: Contains the individual applications. Each application has its own subdirectory.
*   `app-viewer/`: A web-based application to view the available apps.
*   `docs/`: Contains documentation for the project, including contribution guidelines.
*   `PIXLET_VERSION`: Specifies the recommended version of the Pixlet tool.

## Building and Running

To develop and run the applications, you need to have the `pixlet` command-line tool installed. You can find installation instructions in the [Pixlet GitHub repository](https://github.com/tidbyt/pixlet).

### Creating a new app

To create a new app, run the following command:

```sh
pixlet create
```

This will generate a new directory with a basic "Hello, World!" application.

### Running an app

To run an app, use the `pixlet render` command:

```sh
pixlet render apps/<app_name>/<app_name>.star
```

This will render the app and display it in a new window.

### Checking an app

Before submitting an app, you should run the `pixlet check` command to ensure it's ready for publication:

```sh
pixlet check apps/<app_name>/<app_name>.star
```

## Development Conventions

*   Each application must have a `manifest.yaml` file that contains metadata about the app.
*   The main application file should be a `.star` file in a separate directory. An application can consist of multiple Starlark files.
*   Each application should have a `.webp` image that serves as a preview of the app which can be produced by running `pixlet render -z 9` with the app directory as input parameter.
*   If an app supports 2x rendering, it should have a separate 2x preview image with an `@2x.webp` suffix. It can be produced with a command like `pixlet render -2 -z 9 -o apps/app/app@2x.webp`.
*   The code should be formatted according to the Starlark style guide (use `pixlet format`).
*   The code should pass the `pixlet lint` checks.

### Manifest Example

Here is an example of a `manifest.yaml` file:

```yaml
---
id: fuzzy-clock
name: Fuzzy Clock
summary: Human readable time
desc: Display the time in a groovy, human-readable way.
author: Max Timkovich
fileName: fuzzy_clock.star
packageName: fuzzyclock
recommended_interval: 1
supports2x: true
```

### Things to remember

Padding is a 4-tuple `(left, top, right, bottom)`.
