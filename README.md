# Claude Island (iPhone app)

Shows your Claude Code state in the Dynamic Island. Pairs with the relay from `claude-island` (part 1).

## What's in here

- `ClaudeIsland/` the app: address + token screen, relay connection, keep-alive, Live Activity control
- `ClaudeIslandWidget/` the Dynamic Island and lock screen layouts
- `Shared/` the data model both use
- `project.yml` describes the Xcode project (XcodeGen builds it on GitHub, so you never need Xcode)
- `.github/workflows/build.yml` builds an unsigned `.ipa` on a free GitHub Mac

## Build it (GitHub, no Mac needed)

1. Put these files in a **public** GitHub repo (the folder contents at the top level of the repo, including the hidden `.github` folder).
2. Open the repo's **Actions** tab. The "Build IPA" workflow runs on every push, or press **Run workflow**.
3. When it turns green (a few minutes), open the run and download the **ClaudeIsland-ipa** artifact. Unzip it to get `ClaudeIsland.ipa`.

## Install it (Windows, free Apple ID)

1. Install **Sideloadly** (sideloadly.io) on your PC. It needs iTunes and iCloud from apple.com, not the Microsoft Store versions.
2. Plug in your iPhone, trust the computer, and turn on **Developer Mode** (Settings > Privacy & Security) if iOS asks.
3. Drag `ClaudeIsland.ipa` into Sideloadly, enter your Apple ID, and press Start. If it complains the bundle ID is taken, change it under Advanced Options to something unique.
4. On the iPhone: Settings > General > VPN & Device Management > trust your Apple ID.
5. Free Apple IDs expire apps after **7 days**: repeat step 3 weekly (or use AltStore to auto-refresh).

## Use it

1. Open the app, enter your PC's address like `192.168.1.50:8787` (find the IP with `ipconfig` on the PC) and the token from `config.json`.
2. Allow the local network prompt, press **Connect**, and allow Live Activities if asked.
3. Leave the app open in the app switcher. Don't swipe it away.
4. If the island disappears (iOS caps Live Activities at roughly 8 hours), open the app once to bring it back.
