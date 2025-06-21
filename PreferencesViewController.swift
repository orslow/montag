import Cocoa
import ObjectiveC

// Custom text field that handles keyboard shortcuts directly
class KeyboardAwareTextField: NSTextField {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isEditable = true
        isSelectable = true
        usesSingleLineMode = true
    }
    
    override func keyDown(with event: NSEvent) {
        // Handle command key combinations
        if event.modifierFlags.contains(.command) {
            let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""
            
            switch characters {
            case "a": // Select All
                selectText(self)
                return
            case "c": // Copy
                if let fieldEditor = currentEditor() {
                    fieldEditor.copy(self)
                    return
                }
            case "x": // Cut
                if let fieldEditor = currentEditor() {
                    fieldEditor.cut(self)
                    return
                }
            case "v": // Paste
                if let fieldEditor = currentEditor() {
                    fieldEditor.paste(self)
                    return
                }
            case "z": // Undo/Redo
                if event.modifierFlags.contains(.shift) {
                    // Redo
                    if let fieldEditor = currentEditor() {
                        fieldEditor.undoManager?.redo()
                        return
                    }
                } else {
                    // Undo
                    if let fieldEditor = currentEditor() {
                        fieldEditor.undoManager?.undo()
                        return
                    }
                }
            default:
                break
            }
        }
        
        // Let the superclass handle other key events
        super.keyDown(with: event)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}

class PreferencesViewController: NSViewController {
    private var configurationManager: ConfigurationManager
    private var shortcutRecorder: ShortcutRecorder!
    private var startupCheckbox: NSButton!
    
    // Store text fields for direct access
    private var titleFields: [KeyboardAwareTextField] = []
    private var urlFields: [KeyboardAwareTextField] = []
    
    // Callback to notify when preferences are saved
    var onSave: (() -> Void)?
    
    init(configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView()
        view.frame = NSRect(x: 0, y: 0, width: 500, height: 280) // More compact size
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // Ensure undo manager is available for text fields
    override var undoManager: UndoManager? {
        // Make sure we have an undo manager
        if let windowUndoManager = view.window?.undoManager {
            return windowUndoManager
        } else if let appUndoManager = NSApp.mainWindow?.undoManager {
            return appUndoManager
        }
        return super.undoManager
    }
    
    private func setupUI() {
        // Create a main container with Auto Layout
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Set up constraints for the container
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        // Set up the "Open at Startup" checkbox
        startupCheckbox = NSButton(checkboxWithTitle: "Open at startup", target: self, action: #selector(startupCheckboxClicked(_:)))
        startupCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the actual current login status
        let launchHelper = LaunchAtLoginHelper()
        let isEnabled = launchHelper.isLaunchAtLoginEnabled()
        startupCheckbox.state = isEnabled ? .on : .off
        
        // Make sure the configuration is in sync with the actual state
        configurationManager.openAtStartup = isEnabled
        
        containerView.addSubview(startupCheckbox)
        
        // Global shortcut recorder label
        let shortcutLabel = NSTextField(labelWithString: "Global Shortcut:")
        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        shortcutLabel.alignment = .right
        containerView.addSubview(shortcutLabel)
        
        // Shortcut recorder
        shortcutRecorder = ShortcutRecorder(frame: .zero)
        shortcutRecorder.translatesAutoresizingMaskIntoConstraints = false
        shortcutRecorder.shortcutKey = configurationManager.globalShortcut
        shortcutRecorder.delegate = self
        containerView.addSubview(shortcutRecorder)
        
        // Web pages section label
        let webpagesLabel = NSTextField(labelWithString: "Web Pages:")
        webpagesLabel.translatesAutoresizingMaskIntoConstraints = false
        webpagesLabel.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        containerView.addSubview(webpagesLabel)
        
        // Position the startup checkbox and shortcut controls
        NSLayoutConstraint.activate([
            startupCheckbox.topAnchor.constraint(equalTo: containerView.topAnchor),
            startupCheckbox.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            
            shortcutLabel.topAnchor.constraint(equalTo: startupCheckbox.bottomAnchor, constant: 12),
            shortcutLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            shortcutLabel.widthAnchor.constraint(equalToConstant: 120),
            
            shortcutRecorder.centerYAnchor.constraint(equalTo: shortcutLabel.centerYAnchor),
            shortcutRecorder.leadingAnchor.constraint(equalTo: shortcutLabel.trailingAnchor, constant: 8),
            shortcutRecorder.widthAnchor.constraint(equalToConstant: 180),
            shortcutRecorder.heightAnchor.constraint(equalToConstant: 24),
            
            webpagesLabel.topAnchor.constraint(equalTo: shortcutLabel.bottomAnchor, constant: 20),
            webpagesLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        // Create a divider line below the web pages label
        let divider = NSView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        containerView.addSubview(divider)
        
        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: webpagesLabel.bottomAnchor, constant: 8),
            divider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Create web page fields with Auto Layout
        let spacing: CGFloat = 8
        let fieldHeight: CGFloat = 22
        var lastView: NSView = divider
        
        for i in 0..<3 {
            // Create label container for each row
            let rowContainer = NSView()
            rowContainer.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(rowContainer)
            
            NSLayoutConstraint.activate([
                rowContainer.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 12),
                rowContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                rowContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                rowContainer.heightAnchor.constraint(equalToConstant: fieldHeight)
            ])
            
            // Title label and field
            let titleLabel = NSTextField(labelWithString: "Title \(i+1):")
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.alignment = .right
            rowContainer.addSubview(titleLabel)
            
            let titleField = KeyboardAwareTextField(frame: .zero)
            titleField.translatesAutoresizingMaskIntoConstraints = false
            titleField.stringValue = i < configurationManager.webpages.count ? configurationManager.webpages[i].title : ""
            titleField.identifier = NSUserInterfaceItemIdentifier("title\(i+1)Field")
            titleField.placeholderString = "Enter title"
            rowContainer.addSubview(titleField)
            titleFields.append(titleField)
            
            // URL label and field
            let urlLabel = NSTextField(labelWithString: "URL \(i+1):")
            urlLabel.translatesAutoresizingMaskIntoConstraints = false
            urlLabel.alignment = .right
            rowContainer.addSubview(urlLabel)
            
            let urlField = KeyboardAwareTextField(frame: .zero)
            urlField.translatesAutoresizingMaskIntoConstraints = false
            urlField.stringValue = i < configurationManager.webpages.count ? configurationManager.webpages[i].url : ""
            urlField.identifier = NSUserInterfaceItemIdentifier("url\(i+1)Field")
            urlField.placeholderString = "Enter URL"
            rowContainer.addSubview(urlField)
            urlFields.append(urlField)
            
            // Set constraints for the fields
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor),
                titleLabel.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),
                titleLabel.widthAnchor.constraint(equalToConstant: 60),
                
                titleField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: spacing),
                titleField.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),
                titleField.widthAnchor.constraint(equalTo: rowContainer.widthAnchor, multiplier: 0.3),
                titleField.heightAnchor.constraint(equalToConstant: fieldHeight),
                
                urlLabel.leadingAnchor.constraint(equalTo: titleField.trailingAnchor, constant: 12),
                urlLabel.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),
                urlLabel.widthAnchor.constraint(equalToConstant: 50),
                
                urlField.leadingAnchor.constraint(equalTo: urlLabel.trailingAnchor, constant: spacing),
                urlField.trailingAnchor.constraint(equalTo: rowContainer.trailingAnchor),
                urlField.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),
                urlField.heightAnchor.constraint(equalToConstant: fieldHeight)
            ])
            
            lastView = rowContainer
        }
        
        // Save button
        let saveButton = NSButton(title: "Save", target: self, action: #selector(savePreferences(_:)))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.bezelStyle = .rounded
        containerView.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
            saveButton.heightAnchor.constraint(equalToConstant: 24),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Set up keyboard navigation
        for i in 0..<titleFields.count {
            // Set tab order: title1 -> url1 -> title2 -> url2 -> title3 -> url3
            if i < titleFields.count - 1 {
                titleFields[i].nextKeyView = urlFields[i]
                urlFields[i].nextKeyView = titleFields[i+1]
            } else {
                titleFields[i].nextKeyView = urlFields[i]
                urlFields[i].nextKeyView = saveButton
            }
        }
        saveButton.nextKeyView = titleFields[0]
    }
    
    
    @objc private func startupCheckboxClicked(_ sender: NSButton) {
        let enabled = (sender.state == .on)
        configurationManager.openAtStartup = enabled
        
        // Apply the setting immediately
        let launchHelper = LaunchAtLoginHelper()
        launchHelper.setLaunchAtLogin(enabled: enabled)
        
        // Save the configuration
        configurationManager.saveConfiguration()
    }
    
    @objc private func savePreferences(_ sender: NSButton) {
        // Save web page settings from the fields
        var updatedWebPages: [WebPage] = []
        
        for i in 0..<3 {
            updatedWebPages.append(WebPage(
                title: titleFields[i].stringValue,
                url: urlFields[i].stringValue
            ))
        }
        
        configurationManager.webpages = updatedWebPages
        configurationManager.saveConfiguration()
        
        // Apply startup setting
        let launchHelper = LaunchAtLoginHelper()
        launchHelper.setLaunchAtLogin(enabled: configurationManager.openAtStartup)
        
        // Update global shortcut
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.registerGlobalShortcut()
        }
        
        // Notify about preferences save
        onSave?()
        
        // Close preferences window
        if let window = self.view.window {
            window.close()
        }
    }
}

extension PreferencesViewController: ShortcutRecorderDelegate {
    func shortcutRecorderDidChangeShortcut(_ shortcutRecorder: ShortcutRecorder) {
        configurationManager.globalShortcut = shortcutRecorder.shortcutKey
        
        // Update the shortcut immediately
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.registerGlobalShortcut()
        }
    }
}

// Simple shortcut recorder implementation
protocol ShortcutRecorderDelegate: AnyObject {
    func shortcutRecorderDidChangeShortcut(_ shortcutRecorder: ShortcutRecorder)
}

class ShortcutRecorder: NSView {
    weak var delegate: ShortcutRecorderDelegate?
    private var isRecording = false
    private var textField: NSTextField!
    
    var shortcutKey: ShortcutKey? {
        didSet {
            updateTextField()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 4.0
        layer?.borderWidth = 1.0
        layer?.borderColor = NSColor.separatorColor.cgColor
        
        textField = NSTextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.alignment = .center
        addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
        
        updateTextField()
    }
    
    private func updateTextField() {
        if let shortcut = shortcutKey {
            // This is a simple placeholder - in a real app, you'd convert keyCode to human-readable string
            let modifierString = modifierFlagsToString(shortcut.modifierFlags)
            let keyString = keyCodeToString(shortcut.keyCode)
            textField.stringValue = "\(modifierString)\(keyString)"
        } else {
            textField.stringValue = "Click to record shortcut"
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            isRecording = true
            textField.stringValue = "Recording... Press keys"
            layer?.borderColor = NSColor.systemBlue.cgColor
            
            // Make this view the first responder
            window?.makeFirstResponder(self)
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if isRecording {
            // Ignore standalone modifier keys
            if !isModifierKey(event.keyCode) {
                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                shortcutKey = ShortcutKey(keyCode: event.keyCode, modifiers: modifiers)
                isRecording = false
                layer?.borderColor = NSColor.separatorColor.cgColor
                
                delegate?.shortcutRecorderDidChangeShortcut(self)
                window?.makeFirstResponder(nil)
            }
        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        if isRecording {
            isRecording = false
            layer?.borderColor = NSColor.separatorColor.cgColor
            updateTextField()
            window?.makeFirstResponder(nil)
        }
    }
    
    private func isModifierKey(_ keyCode: UInt16) -> Bool {
        return keyCode == 54 || // Right Command
               keyCode == 55 || // Left Command
               keyCode == 56 || // Left Shift
               keyCode == 57 || // Caps Lock
               keyCode == 58 || // Left Alt/Option
               keyCode == 59 || // Left Control
               keyCode == 60 || // Right Shift
               keyCode == 61 || // Right Alt/Option
               keyCode == 62    // Right Control
    }
    
    private func modifierFlagsToString(_ modifierFlags: NSEvent.ModifierFlags) -> String {
        var result = ""
        
        if modifierFlags.contains(.command) {
            result += "⌘"
        }
        if modifierFlags.contains(.option) {
            result += "⌥"
        }
        if modifierFlags.contains(.control) {
            result += "⌃"
        }
        if modifierFlags.contains(.shift) {
            result += "⇧"
        }
        
        return result
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        // This is a simplified implementation - a real app would have a complete mapping
        let keyCodes: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
            44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space", 50: "`",
            51: "Delete", 53: "Escape", 65: ".", 67: "*", 69: "+", 71: "Clear",
            75: "/", 76: "Enter", 78: "-", 81: "=", 82: "0", 83: "1", 84: "2",
            85: "3", 86: "4", 87: "5", 88: "6", 89: "7", 91: "8", 92: "9",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
            109: "F10", 111: "F11", 118: "F4", 120: "F2", 122: "F1", 123: "F12"
        ]
        
        return keyCodes[keyCode] ?? "Key\(keyCode)"
    }
}