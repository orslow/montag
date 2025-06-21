import Foundation
import ServiceManagement
import AppKit

class LaunchAtLoginHelper {
    private let defaults = UserDefaults.standard
    private let launchAtLoginKey = "LaunchAtLoginEnabled"
    
    // Main method to set launch at login state
    func setLaunchAtLogin(enabled: Bool) {
        // For macOS 13 and later
        if #available(macOS 13.0, *) {
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.montag"
            let appService = SMAppService.mainApp
            
            do {
                if enabled {
                    if appService.status != .enabled {
                        try appService.register()
                        NSLog("Successfully registered app for launch at login")
                    }
                } else {
                    if appService.status == .enabled {
                        try appService.unregister()
                        NSLog("Successfully unregistered app from launch at login")
                    }
                }
                // Save the preference
                defaults.set(enabled, forKey: launchAtLoginKey)
            } catch {
                NSLog("Error managing launch at login: \(error.localizedDescription)")
                
                // Handle the case when we don't have permission by opening System Settings
                askForPermission()
            }
        } 
        // For macOS 12 and earlier
        else {
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.montag"
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
            
            if success {
                NSLog("Successfully \(enabled ? "enabled" : "disabled") launch at login using legacy API")
                defaults.set(enabled, forKey: launchAtLoginKey)
            } else {
                NSLog("Failed to \(enabled ? "enable" : "disable") launch at login")
                askForPermission()
            }
        }
    }
    
    // Check if launch at login is currently enabled
    func isLaunchAtLoginEnabled() -> Bool {
        // For macOS 13 and later
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            let isEnabled = status == .enabled
            
            // Keep our saved preference in sync with actual state
            if defaults.bool(forKey: launchAtLoginKey) != isEnabled {
                defaults.set(isEnabled, forKey: launchAtLoginKey)
            }
            
            return isEnabled
        } 
        // For macOS 12 and earlier
        else {
            // Rely on our saved preference since there's no reliable way to check
            return defaults.bool(forKey: launchAtLoginKey)
        }
    }
    
    // Open System Settings/Preferences to Login Items
    private func askForPermission() {
        let alert = NSAlert()
        alert.messageText = "Permission Needed"
        alert.informativeText = "To set this app to open at login, you need to add it to Login Items in System Settings."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            openLoginItemsPreferences()
        }
    }
    
    // Open the Login Items preferences panel
    private func openLoginItemsPreferences() {
        var url: URL
        
        if #available(macOS 13, *) {
            // macOS 13 Ventura and later
            url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
        } else {
            // macOS 12 and earlier
            url = URL(string: "x-apple.systempreferences:com.apple.preferences.users")!
        }
        
        NSWorkspace.shared.open(url)
    }
}