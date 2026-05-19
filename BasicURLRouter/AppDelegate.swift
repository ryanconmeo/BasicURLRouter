import Cocoa

private struct Rule: Decodable {
    var match: String
    var browser: String
}

private struct Config: Decodable {
    var defaultBrowser: String = "com.google.Chrome"
    var rules: [Rule] = [
        Rule(match: "dev.azure.com", browser: "com.apple.Safari"),
        Rule(match: "visualstudio.com", browser: "com.apple.Safari"),
        Rule(match: "ado", browser: "com.apple.Safari")
    ]

    static func load() -> Config {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/BasicURLRouter/config.json")
        guard let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return Config()
        }
        return config
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    private let internetEventClass = AEEventClass(0x4755524C) // 'GURL'
    private let getURLEventID = AEEventID(0x4755524C)         // 'GURL'

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerLaunchAgent()
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: internetEventClass,
            andEventID: getURLEventID
        )
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        let keyDirectObject = AEKeyword(0x2D2D2D2D) // '----'
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }
        route(url)
    }

    private func registerLaunchAgent() {
        let plistURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.ryannguyen.BasicURLRouter.plist")
        guard !FileManager.default.fileExists(atPath: plistURL.path) else { return }

        let executablePath = Bundle.main.executablePath ?? "/Applications/BasicURLRouter.app/Contents/MacOS/BasicURLRouter"
        let plist: NSDictionary = [
            "Label": "com.ryannguyen.BasicURLRouter",
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        try? FileManager.default.createDirectory(at: plistURL.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        plist.write(to: plistURL, atomically: true)
    }

    private func browser(for url: URL, config: Config) -> String {
        let host = url.host ?? ""

        if let rule = config.rules.first(where: { host.contains($0.match) }) {
            return rule.browser
        }

        // Check the full decoded URL string so wrapped/tracking links (e.g. Outlook Safe Links)
        // are matched regardless of which query param or path segment holds the target URL.
        let raw = url.absoluteString
        let decoded = raw.removingPercentEncoding ?? raw
        if let rule = config.rules.first(where: { decoded.contains($0.match) }) {
            return rule.browser
        }

        return config.defaultBrowser
    }

    private func route(_ url: URL) {
        let bundleID = browser(for: url, config: Config.load())
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}
