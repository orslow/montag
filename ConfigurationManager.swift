import Foundation
import Cocoa

struct WebPage: Codable {
    var title: String
    var url: String
}

struct ShortcutKey: Codable {
    var keyCode: UInt16
    var modifiers: UInt
    
    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers.rawValue
    }
    
    var modifierFlags: NSEvent.ModifierFlags {
        return NSEvent.ModifierFlags(rawValue: modifiers)
    }
}

class ConfigurationManager {
    private let userDefaultsKey = "MontagAppConfiguration"
    
    var openAtStartup: Bool = false
    var globalShortcut: ShortcutKey? = ShortcutKey(keyCode: 35, modifiers: .command) // Default to Cmd+P
    // Always maintain exactly 3 webpages
    var webpages: [WebPage] = [
        WebPage(title: "Page 1", url: "https://example.com"),
        WebPage(title: "Page 2", url: "https://example.org"),
        WebPage(title: "Page 3", url: "https://example.net")
    ]
    
    init() {
        loadConfiguration()
    }
    
    func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                let decoder = JSONDecoder()
                let config = try decoder.decode(Configuration.self, from: data)
                self.openAtStartup = config.openAtStartup
                self.globalShortcut = config.globalShortcut
                self.webpages = config.webpages
            } catch {
                print("Failed to load configuration: \(error.localizedDescription)")
            }
        }
    }
    
    func saveConfiguration() {
        let config = Configuration(
            openAtStartup: openAtStartup,
            globalShortcut: globalShortcut,
            webpages: webpages
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(config)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save configuration: \(error.localizedDescription)")
        }
    }
    
    private struct Configuration: Codable {
        var openAtStartup: Bool
        var globalShortcut: ShortcutKey?
        var webpages: [WebPage]
    }
}