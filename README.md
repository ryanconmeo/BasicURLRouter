# BasicURLRouter

A minimal macOS app that registers as your default browser and routes URLs to different browsers based on rules you define.

## How it works

When you click a link anywhere on your Mac, BasicURLRouter intercepts it, checks the URL against your rules, and opens it in the right browser. If no rule matches, it falls back to your default browser.

## Installation

1. Clone and open in Xcode
2. Change the bundle identifier from `com.ryannguyen.BasicURLRouter` to your own (e.g. `com.yourname.BasicURLRouter`)
3. Set your signing team
4. Build and copy `BasicURLRouter.app` to `/Applications`
5. Go to **System Settings → Desktop & Dock → Default web browser** and select BasicURLRouter
6. Launch the app — it runs as a background agent and registers itself to start at login

## Configuration

Create `~/.config/BasicURLRouter/config.json`:

```json
{
  "defaultBrowser": "com.google.Chrome",
  "rules": [
    { "match": "dev.azure.com", "browser": "com.apple.Safari" },
    { "match": "github.com", "browser": "com.mozilla.firefox" }
  ]
}
```

Rules are checked in order — the first match wins. Each rule matches against the URL's hostname. Changes take effect immediately with no restart required.

If no config file exists, the app defaults to routing `dev.azure.com`, `visualstudio.com`, and any host containing `ado` to Safari, and everything else to Chrome.

### Common browser bundle IDs

| Browser | Bundle ID |
|---|---|
| Safari | `com.apple.Safari` |
| Chrome | `com.google.Chrome` |
| Firefox | `org.mozilla.firefox` |
| Arc | `company.thebrowser.Browser` |
| Edge | `com.microsoft.edgemac` |

## Similar apps

- [Finicky](https://github.com/johnste/finicky) — more powerful, JavaScript-based config
- [Choosy](https://www.choosyosx.com) — GUI-based, paid
