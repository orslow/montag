import Cocoa

class MenuManager {
    private weak var appDelegate: AppDelegate?
    private var configurationManager: ConfigurationManager
    
    init(appDelegate: AppDelegate, configurationManager: ConfigurationManager) {
        self.appDelegate = appDelegate
        self.configurationManager = configurationManager
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Add the web pages as menu items
        for (index, webpage) in configurationManager.webpages.enumerated() {
            let item = NSMenuItem(title: webpage.title, action: #selector(openWebPage(_:)), keyEquivalent: "\(index + 1)")
            item.keyEquivalentModifierMask = .command
            item.tag = index
            item.target = self
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Preferences
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences(_:)), keyEquivalent: ",")
        preferencesItem.keyEquivalentModifierMask = .command
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)
        
        appDelegate?.statusBarItem.menu = menu
    }
    
    @objc private func openWebPage(_ sender: NSMenuItem) {
        if let webViewController = appDelegate?.webViewController {
            webViewController.loadWebPage(at: sender.tag)
            appDelegate?.togglePopover()
        }
    }
    
    @objc private func openPreferences(_ sender: NSMenuItem) {
        let preferencesViewController = PreferencesViewController(configurationManager: configurationManager)
        let preferencesWindow = NSWindow(
            contentRect: preferencesViewController.view.frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        preferencesWindow.title = "Preferences"
        preferencesWindow.contentViewController = preferencesViewController
        preferencesWindow.center()
        
        NSApp.runModal(for: preferencesWindow)
        
        // Update menu after preferences might have changed
        setupMenu()
    }
}