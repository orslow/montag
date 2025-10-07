import Cocoa
import SwiftUI
import WebKit
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var webViewController: WebViewController!
    var shortcutMonitor: [Any]?
    var configurationManager = ConfigurationManager()
    
    // Create a menu to handle Cmd+Q and other standard menu items
    private var mainMenu: NSMenu!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupMenuBarItem()
        setupPopover()
        registerGlobalShortcut()
        
        if configurationManager.openAtStartup {
            registerForStartup()
        }
    }
    
    private func setupMainMenu() {
        // Create the main menu
        mainMenu = NSMenu()
        
        // Create the application menu (first menu)
        let appMenu = NSMenu()
        
        // Add menu items to the app menu
        let aboutMenuItem = NSMenuItem(title: "About montag", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(aboutMenuItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let preferencesMenuItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        appMenu.addItem(preferencesMenuItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let quitMenuItem = NSMenuItem(title: "Quit montag", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitMenuItem)
        
        // Create app menu item and assign the appMenu as its submenu
        let appMenuItem = NSMenuItem(title: "montag", action: nil, keyEquivalent: "")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // Create Edit menu
        let editMenu = NSMenu(title: "Edit")
        
        // Add standard edit menu items
        let undoMenuItem = NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(undoMenuItem)
        
        let redoMenuItem = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redoMenuItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoMenuItem)
        
        editMenu.addItem(NSMenuItem.separator())
        
        let cutMenuItem = NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(cutMenuItem)
        
        let copyMenuItem = NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(copyMenuItem)
        
        let pasteMenuItem = NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(pasteMenuItem)
        
        editMenu.addItem(NSMenuItem.separator())
        
        let selectAllMenuItem = NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(selectAllMenuItem)
        
        // Create edit menu item and assign the editMenu as its submenu
        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        // Set the menu as the application's main menu
        NSApplication.shared.mainMenu = mainMenu
    }
    
    @objc private func showAbout() {
        // Use the standard selector to show the About panel
        NSApplication.shared.sendAction(#selector(NSApplication.orderFrontStandardAboutPanel(_:)), to: nil, from: nil)
    }
    
    @objc private func showPreferences() {
        togglePopover()
        
        // Open preferences after a small delay to ensure popover is shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let webViewController = self?.webViewController {
                let preferencesSelector = NSSelectorFromString("openPreferences:")
                if webViewController.responds(to: preferencesSelector) {
                    webViewController.perform(preferencesSelector, with: nil)
                }
            }
        }
    }
    
    func setupMenuBarItem() {
        // Use standard status item width for smaller icon
        statusBarItem = NSStatusBar.system.statusItem(withLength: 24)
        
        if let button = statusBarItem.button {
            // Use the simple book image from asset catalog as the menu bar icon
            if let menuBarImage = NSImage(named: "MenuBarIcon") {
                // The image is already configured as a template in the asset catalog
                // Resize the image to standard menu bar size
                let resizedImage = NSImage(size: NSSize(width: 16, height: 16))
                resizedImage.lockFocus()
                
                // Draw the original image in the resized context
                menuBarImage.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16),
                          from: NSRect(x: 0, y: 0, width: menuBarImage.size.width, height: menuBarImage.size.height),
                          operation: .sourceOver,
                          fraction: 1.0)
                resizedImage.unlockFocus()
                
                // Set as template image (automatically adapts to dark/light mode)
                resizedImage.isTemplate = true
                
                button.image = resizedImage
            } else {
                // Fallback to loading directly from the file if asset catalog fails
                let directPath = "/Users/jueon/Documents/git/montag/simple_book.png"
                if let image = NSImage(contentsOfFile: directPath) {
                    // Resize for menu bar (standard size)
                    let resizedImage = NSImage(size: NSSize(width: 16, height: 16))
                    resizedImage.lockFocus()
                    
                    // Draw the original image in the resized context
                    image.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16),
                              from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
                              operation: .sourceOver,
                              fraction: 1.0)
                    resizedImage.unlockFocus()
                    
                    // Set as template image (automatically adapts to dark/light mode)
                    resizedImage.isTemplate = true
                    
                    button.image = resizedImage
                } else {
                    // Fallback to text if all image loading attempts fail
                    button.title = "L"
                }
            }
            
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    func setupPopover() {
        popover = NSPopover()
        webViewController = WebViewController(configurationManager: configurationManager)
        popover.contentViewController = webViewController
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 600, height: 880)
    }
    
    @objc func togglePopover() {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()

                // Focus the first textbox after popover is shown
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.webViewController.focusFirstTextbox()
                }
            }
        }
    }
    
    func registerGlobalShortcut() {
        // Remove any existing shortcut monitors
        if let existingMonitors = shortcutMonitor {
            for monitor in existingMonitors {
                NSEvent.removeMonitor(monitor)
            }
            shortcutMonitor = nil
        }
        
        guard let shortcutKey = configurationManager.globalShortcut else { return }
        
        print("Registering shortcut: Key code \(shortcutKey.keyCode), modifiers \(shortcutKey.modifiers)")
        
        // Local monitor (works without accessibility permissions)
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(shortcutKey.modifierFlags) && 
               event.keyCode == shortcutKey.keyCode {
                print("Local shortcut triggered")
                DispatchQueue.main.async {
                    self?.togglePopover()
                }
                return nil // Consume the event
            }
            return event // Pass the event along
        }
        
        // Global monitor (requires accessibility permissions)
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(shortcutKey.modifierFlags) && 
               event.keyCode == shortcutKey.keyCode {
                print("Global shortcut triggered")
                DispatchQueue.main.async {
                    self?.togglePopover()
                }
            }
        }
        
        // Store both monitors
        shortcutMonitor = [localMonitor as Any, globalMonitor as Any]
        
        // Check if accessibility permissions are granted and show instructions if not
        checkAccessibilityPermissions()
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "To use global shortcuts, montag needs accessibility permissions. Please go to System Preferences > Security & Privacy > Privacy > Accessibility and add montag to the list of allowed apps."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            
            DispatchQueue.main.async {
                alert.runModal()
            }
        }
    }
    
    func registerForStartup() {
        let launchAtLoginHelper = LaunchAtLoginHelper()
        launchAtLoginHelper.setLaunchAtLogin(enabled: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources
        if let monitors = shortcutMonitor {
            for monitor in monitors {
                NSEvent.removeMonitor(monitor)
            }
        }
        
        // Save configuration before exit
        configurationManager.saveConfiguration()
    }
    
    // Handle application should terminate
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Perform any cleanup required before termination
        print("Application is about to terminate")
        
        // Save configuration one last time
        configurationManager.saveConfiguration()
        
        // Allow the application to terminate
        return .terminateNow
    }
}
