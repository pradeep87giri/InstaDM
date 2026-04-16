# InstaDM

An iOS app that gives you Instagram Direct Messages — and nothing else.

No feed. No Reels. No Explore. No Stories. Just your conversations.

Built for people who want to stay connected with friends on Instagram without falling into the doom-scrolling trap.

---

## How It Works

InstaDM is a focused iOS app built on a WebKit view that loads Instagram's DM inbox directly. It actively blocks any navigation away from the messages section:

- Redirects you back to the inbox if you land on the feed, Explore, or Reels
- Detects fullscreen Reel overlays (even when the URL doesn't change) and closes them instantly
- Blocks Stories and post pages from loading
- Preserves your Instagram login session across app launches

You get the full DM experience — voice messages, photos, video clips, reactions, GIFs — without any of the addictive parts of Instagram.

---

## Requirements

- A Mac running macOS 13 or later
- Xcode 15 or later (free from the Mac App Store)
- An iPhone running iOS 16 or later
- A free Apple ID (no paid developer account required)

---

## Installation

### 1. Download the project

Clone or download this repository to your Mac:

```bash
git clone https://github.com/YOUR_USERNAME/InstaDM.git
```

Or click **Code → Download ZIP** on GitHub and unzip it.

### 2. Open in Xcode

Open `InstaDM.xcodeproj` (or the `.xcworkspace` if one exists) in Xcode.

### 3. Set your development team

1. In Xcode, click on the **InstaDM** project in the left sidebar
2. Select the **InstaDM** target
3. Go to the **Signing & Capabilities** tab
4. Under **Team**, select your Apple ID from the dropdown
   - If your Apple ID isn't listed, go to **Xcode → Settings → Accounts** and add it
5. Change the **Bundle Identifier** to something unique, e.g. `com.yourname.instadm`

### 4. Connect your iPhone

Plug your iPhone into your Mac with a USB cable. Trust the computer if prompted on your device.

In Xcode, select your iPhone from the device picker at the top of the window.

### 5. Build and install

Press **⌘R** (or click the Run button). Xcode will build the app and install it on your iPhone.

The first time you run it, iOS may say the developer is not trusted. Fix this by going to:

**Settings → General → VPN & Device Management → [Your Apple ID] → Trust**

---

## Rebuilding Every 7 Days

> **Important limitation:** Apps installed with a free Apple ID expire after **7 days**. When the app stops opening, you need to rebuild it from Xcode.

To rebuild:

1. Plug your iPhone into your Mac
2. Open the project in Xcode
3. Press **⌘R**

That's it. Your login session is preserved — you won't need to log back into Instagram.

**Want to avoid this?** A paid [Apple Developer Program](https://developer.apple.com/programs/) membership ($99/year) lets you install apps that stay valid for a full year.

---

## Usage

1. Open the app on your iPhone
2. Log into Instagram the first time (your session is saved after that)
3. You'll land directly in your DM inbox
4. Any attempt to navigate to the feed, Reels, Explore, or Stories is automatically blocked and redirected back to messages

---

## Privacy

- This app does not collect any data
- Your Instagram login is stored locally on your device in the standard WebKit cookie/session store — the same way Safari stores it
- No analytics, no tracking, no servers

---

## Disclaimer

InstaDM is an unofficial, open-source tool not affiliated with or endorsed by Instagram or Meta. It uses Instagram's public web interface the same way a browser would. Use it at your own discretion and in accordance with Instagram's Terms of Service.

---

## Contributing

Pull requests are welcome. If you find a case where a distraction slips through (a new URL pattern, a Reel variant, etc.), open an issue or submit a fix to `ContentView.swift`.

---

## License

MIT — free to use, modify, and distribute.
