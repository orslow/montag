# Montag - Lightweight Web Page Menu Bar App

Montag is a simple, lightweight macOS menu bar application for quick access to your favorite web pages.

## Features

- Access up to 3 customizable web pages from the menu bar
- Clean, minimal interface for distraction-free browsing
- Global keyboard shortcut support for quick access
- Option to launch at system startup
- Compact design that stays out of your way

## Requirements

- macOS 13.0+
- Xcode 14.0+ (for building)

## Installation

Build from source:

```bash
git clone https://github.com/orslow/montag.git
cd montag
xcodebuild -project montag.xcodeproj
```

Then build and run in Xcode.

## Usage

1. Click the menu bar icon to show your primary web page
2. Use the radio buttons at the bottom to switch between your configured pages
3. Press the gear icon to open Preferences
4. Configure your web pages, global shortcut, and startup options in Preferences

### Keyboard Shortcuts

- ⌘1, ⌘2, ⌘3: Switch between configured web pages
- Global shortcut (configurable): Show/hide the app

## Customization

In the Preferences window, you can:
- Set up to 3 web pages with custom titles and URLs
- Configure a global keyboard shortcut
- Choose whether to launch the app at system startup

## Building from Source

1. Clone the repository
2. Open the Xcode project
3. Build the application

## License

[MIT License](LICENSE)

## Acknowledgements

- Inspired by the need for quick access to frequently used web pages
- Built with Swift and AppKit
