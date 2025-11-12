import Cocoa
import SwiftUI
import WebKit
import ApplicationServices
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var webViewController: WebViewController!
    var shortcutMonitor: [Any]?
    var globalHotKeyRef: EventHotKeyRef?
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
        // Remove any existing shortcut monitors and hotkeys
        unregisterGlobalShortcut()
        
        guard let shortcutKey = configurationManager.globalShortcut else { return }
        
        print("Registering shortcut: Key code \(shortcutKey.keyCode), modifiers \(shortcutKey.modifiers)")
        
        // Convert NSEvent modifier flags to Carbon modifier flags
        var carbonModifiers: UInt32 = 0
        let nsModifiers = shortcutKey.modifierFlags
        
        if nsModifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if nsModifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if nsModifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        if nsModifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        
        // Register Carbon global hotkey (this properly intercepts the shortcut system-wide)
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("MTAG".utf8.reduce(0) { ($0 << 8) + UInt32($1) })
        hotKeyID.id = 1
        
        let status = RegisterEventHotKey(
            UInt32(shortcutKey.keyCode),
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &globalHotKeyRef
        )
        
        if status == noErr {
            print("Global hotkey registered successfully")
            // Install event handler for the hotkey
            installCarbonEventHandler()
        } else {
            print("Failed to register global hotkey: \(status)")
        }
        
        // Fallback: Local monitor for when the app is active
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(shortcutKey.modifierFlags) && 
               event.keyCode == shortcutKey.keyCode {
                print("Local shortcut triggered")
                DispatchQueue.main.async {
                    self?.togglePopover()
                }
                return nil // Consume the event completely - prevents passthrough to other apps
            }
            return event // Pass the event along
        }
        
        // Global monitor for when the app is not active (requires accessibility permissions)
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(shortcutKey.modifierFlags) && 
               event.keyCode == shortcutKey.keyCode {
                print("Global shortcut triggered")
                DispatchQueue.main.async {
                    self?.togglePopover()
                }
                // Note: Global monitors cannot return nil to consume events,
                // but Carbon hotkey should handle this case
            }
        }
        
        // Store both monitors
        var monitors: [Any] = [localMonitor as Any]
        if let global = globalMonitor {
            monitors.append(global as Any)
        }
        shortcutMonitor = monitors
    }
    
    private func unregisterGlobalShortcut() {
        // Remove existing monitors
        if let existingMonitors = shortcutMonitor {
            for monitor in existingMonitors {
                NSEvent.removeMonitor(monitor)
            }
            shortcutMonitor = nil
        }
        
        // Unregister Carbon hotkey
        if let hotKeyRef = globalHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            globalHotKeyRef = nil
        }
    }
    
    private func installCarbonEventHandler() {
        var eventHandler: EventHandlerRef?
        let eventTypes = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))]
        
        let handler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            guard let appDelegate = userData?.assumingMemoryBound(to: AppDelegate.self).pointee else {
                return OSStatus(eventNotHandledErr)
            }
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr && hotKeyID.signature == OSType("MTAG".utf8.reduce(0) { ($0 << 8) + UInt32($1) }) {
                print("Carbon hotkey triggered")
                DispatchQueue.main.async {
                    appDelegate.togglePopover()
                }
                return noErr // Event handled - prevents passthrough to other apps
            }
            
            return OSStatus(eventNotHandledErr)
        }
        
        let selfPtr = UnsafeMutablePointer<AppDelegate>.allocate(capacity: 1)
        selfPtr.initialize(to: self)
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            eventTypes,
            selfPtr,
            &eventHandler
        )
    }
    
    
    func registerForStartup() {
        let launchAtLoginHelper = LaunchAtLoginHelper()
        launchAtLoginHelper.setLaunchAtLogin(enabled: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources
        unregisterGlobalShortcut()
        
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
