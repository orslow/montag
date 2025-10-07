import Cocoa
@preconcurrency import WebKit

class WebViewController: NSViewController {
    private var webView: WKWebView!
    private var configurationManager: ConfigurationManager
    private var radioButtons: [NSButton] = []
    
    init(configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView()
        view.frame = NSRect(x: 0, y: 0, width: 550, height: 750)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupRadioButtons()
        loadSelectedWebPage()
        setupShortcuts()
    }
    
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        
        // Configure web view preferences for better user experience
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        webConfiguration.defaultWebpagePreferences = preferences
        
        // Silence alert sounds in web view
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webConfiguration.suppressesIncrementalRendering = false
        
        // Set the user agent to ensure web compatibility
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = "\(osVersion.majorVersion)_\(osVersion.minorVersion)_\(osVersion.patchVersion)"
        let defaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X \(osVersionString)) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"
        webConfiguration.applicationNameForUserAgent = "Montag/1.0 \(defaultUserAgent)"
        
        // Create the web view with auto-resizing
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        
        // Configure for quiet operation
        
        // Make web view automatically resize with its container
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        // We'll set the constraints after creating the buttons container
    }
    
    private func setupRadioButtons() {
        let buttonHeight: CGFloat = 30
        let buttonSpacing: CGFloat = 10
        let configButtonWidth: CGFloat = 40
        let containerHeight: CGFloat = 38
        
        // Create a container view for buttons with a clean background
        let buttonsContainer = NSView(frame: .zero)
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonsContainer.wantsLayer = true
        buttonsContainer.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        view.addSubview(buttonsContainer)
        
        // Set up constraints for the buttons container
        NSLayoutConstraint.activate([
            buttonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            buttonsContainer.heightAnchor.constraint(equalToConstant: containerHeight)
        ])
        
        // Add a divider line at the top of the buttons container
        let divider = NSView(frame: .zero)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        buttonsContainer.addSubview(divider)
        
        // Set up constraints for the divider
        NSLayoutConstraint.activate([
            divider.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: buttonsContainer.trailingAnchor),
            divider.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Calculate button widths
        let availableWidth = view.frame.width - (buttonSpacing * 4) - configButtonWidth - buttonSpacing
        let buttonWidth = min(150, availableWidth / CGFloat(configurationManager.webpages.count))
        
        // Create radio buttons
        for (index, webpage) in configurationManager.webpages.enumerated() {
            let button = NSButton(frame: .zero)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.title = webpage.title
            button.tag = index
            button.setButtonType(.radio)
            button.target = self
            button.action = #selector(radioButtonClicked(_:))
            
            buttonsContainer.addSubview(button)
            radioButtons.append(button)
            
            // Position the button using constraints
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor, constant: buttonSpacing + (buttonWidth + buttonSpacing) * CGFloat(index)),
                button.centerYAnchor.constraint(equalTo: buttonsContainer.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: buttonWidth),
                button.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])
        }
        
        // Add configuration button
        let configButton = NSButton(frame: .zero)
        configButton.translatesAutoresizingMaskIntoConstraints = false
        configButton.title = "⚙️"
        configButton.bezelStyle = .rounded
        configButton.target = self
        configButton.action = #selector(openPreferences(_:))
        buttonsContainer.addSubview(configButton)
        
        // Position the config button using constraints
        NSLayoutConstraint.activate([
            configButton.trailingAnchor.constraint(equalTo: buttonsContainer.trailingAnchor, constant: -buttonSpacing),
            configButton.centerYAnchor.constraint(equalTo: buttonsContainer.centerYAnchor),
            configButton.widthAnchor.constraint(equalToConstant: configButtonWidth),
            configButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
        
        // Select the first radio button by default
        if !radioButtons.isEmpty {
            radioButtons[0].state = .on
        }
        
        // Now that we have the buttons container, we can set the webView constraints
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: buttonsContainer.topAnchor)
        ])
    }
    
    @objc private func viewDidResize() {
        // Since we're using Auto Layout constraints, we don't need to manually
        // update the frame sizes when the view resizes
    }
    
    @objc private func openPreferences(_ sender: NSButton) {
        let preferencesViewController = PreferencesViewController(configurationManager: configurationManager)
        
        // Create the window with proper owner to prevent deallocation
        let preferencesWindow = NSWindow(
            contentRect: preferencesViewController.view.frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        preferencesWindow.title = "Preferences"
        preferencesWindow.contentViewController = preferencesViewController
        preferencesWindow.center()
        
        // Make the window float above other windows
        preferencesWindow.level = NSWindow.Level.floating
        
        // Make it the key window to receive focus
        preferencesWindow.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
        
        // Use windowController to manage the window lifecycle
        let windowController = NSWindowController(window: preferencesWindow)
        windowController.showWindow(sender)
        
        // Set the preferences delegate to handle window close notification
        preferencesViewController.onSave = { [weak self] in
            guard let self = self else { return }
            
            // Remove existing radio buttons
            for button in self.radioButtons {
                button.removeFromSuperview()
            }
            self.radioButtons.removeAll()
            
            // Re-create radio buttons
            self.setupRadioButtons()
            self.loadSelectedWebPage()
        }
    }
    
    @objc private func radioButtonClicked(_ sender: NSButton) {
        loadWebPage(at: sender.tag)
    }
    
    private func loadSelectedWebPage() {
        if let selectedIndex = radioButtons.firstIndex(where: { $0.state == .on }) {
            loadWebPage(at: selectedIndex)
        } else if !configurationManager.webpages.isEmpty {
            loadWebPage(at: 0)
            radioButtons[0].state = .on
        }
    }
    
    func loadWebPage(at index: Int) {
        guard index >= 0 && index < configurationManager.webpages.count else { return }

        let webpage = configurationManager.webpages[index]
        if let url = URL(string: webpage.url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        // Update the radio button states
        for (buttonIndex, button) in radioButtons.enumerated() {
            button.state = buttonIndex == index ? .on : .off
        }
    }

    func focusFirstTextbox() {
        webView.evaluateJavaScript("""
            (function() {
                // Find the first input field that can accept text
                var inputs = document.querySelectorAll('input[type="text"], input[type="search"], input[type="email"], input[type="url"], input[type="tel"], input[type="number"], input:not([type]), textarea');

                // Focus the first visible and enabled input
                for (var i = 0; i < inputs.length; i++) {
                    var input = inputs[i];
                    if (input.offsetParent !== null && !input.disabled && !input.readOnly) {
                        input.focus();
                        return true;
                    }
                }
                return false;
            })();
        """, completionHandler: nil)
    }
    
    private func setupShortcuts() {
        // Track keyboard events
        
        // Add handlers for keyboard events
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // Handle Escape key to exit text field focus
            if event.keyCode == 53 { // ESC key
                // Execute JavaScript to blur any focused element
                self.webView.evaluateJavaScript("""
                    if (document.activeElement && 
                        (document.activeElement.tagName === 'INPUT' || 
                         document.activeElement.tagName === 'TEXTAREA' || 
                         document.activeElement.isContentEditable)) {
                        document.activeElement.blur();
                        true;
                    } else {
                        false;
                    }
                """) { (result, error) in
                    if let blurred = result as? Bool, blurred {
                        // Successfully blurred the active element
                    }
                }
                
                // Also handle native text fields
                if let firstResponder = self.view.window?.firstResponder,
                   (firstResponder is NSTextField || firstResponder is NSTextView) {
                    self.view.window?.makeFirstResponder(self.webView)
                    return nil // Event handled
                }
            }
            
            // Handle Enter key in inputs
            if event.keyCode == 36 { // Return/Enter key
                // Try to detect if we're in an input field
                let script = """
                    (function() {
                        var elem = document.activeElement;
                        return {
                            isInput: elem && (elem.tagName === 'INPUT' || elem.tagName === 'TEXTAREA'),
                            hasForm: elem && elem.form ? true : false,
                            isMultiline: elem && elem.tagName === 'TEXTAREA'
                        };
                    })()
                """
                
                // Use a dispatch group to make this operation more synchronous
                let group = DispatchGroup()
                group.enter()
                
                var shouldSuppressBeep = false
                var shouldPreventDefault = false
                
                // Query the active element
                self.webView.evaluateJavaScript(script) { (result, error) in
                    if let info = result as? [String: Bool],
                       let isInput = info["isInput"],
                       isInput {
                        
                        // We're in an input field, silence the beep and let JavaScript handle it
                        shouldSuppressBeep = true
                        
                        // For single-line inputs, we'll prevent the default action to avoid the beep
                        if let isMultiline = info["isMultiline"], !isMultiline {
                            shouldPreventDefault = true
                            
                            // Call the silence beep function
                            self.webView.evaluateJavaScript("if (window.silenceBeep) window.silenceBeep();", completionHandler: nil)
                        }
                    }
                    
                    group.leave()
                }
                
                // Wait for the check to complete (brief timeout to avoid deadlock)
                _ = group.wait(timeout: .now() + 0.1)
                
                if shouldSuppressBeep {
                    // Create a soft click sound instead of the system beep
                    let sound = NSSound(named: "Tink")
                    sound?.volume = 0.1
                    sound?.play()
                    
                    if shouldPreventDefault {
                        // For single-line inputs, return nil to prevent the default action
                        // This relies on our JavaScript handler to properly submit the form
                        return nil
                    }
                }
                
                // For all other cases, let the event through
                return event
            }
            
            // Handle command key shortcuts
            if event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.option) {
                let keyCode = event.charactersIgnoringModifiers?.lowercased()
                
                // All editing command keys that might cause beeps (V, X, C, A, Z)
                if keyCode == "v" || keyCode == "x" || keyCode == "c" || keyCode == "a" || keyCode == "z" {
                    // Only intercept events if our web view's window is the key window
                    // This allows other windows (like preferences) to handle their own keyboard shortcuts
                    guard let webViewWindow = self.webView.window, webViewWindow.isKeyWindow else {
                        return event // Let other windows handle their events
                    }
                    
                    // Play a single fast silent sound first to prevent beeps
                    if let sound = NSSound(named: "Tink") {
                        sound.volume = 0.0
                        sound.play()
                    }
                    
                    // Immediately execute common commands without waiting for JavaScript
                    // This makes common operations like copy/paste faster
                    let isClipboardOperation = (keyCode == "c" || keyCode == "v" || keyCode == "x")
                    if isClipboardOperation {
                        // Direct execution for clipboard operations - these are fast
                        switch keyCode {
                        case "v": // Paste
                            self.handlePaste()
                        case "c": // Copy
                            self.handleCopy()
                        case "x": // Cut
                            self.handleCut()
                        default:
                            break
                        }
                    }
                    
                    // Run select-all immediately as it's a common operation
                    if keyCode == "a" {
                        self.webView.evaluateJavaScript("document.activeElement.select ? document.activeElement.select() : window.getSelection().selectAllChildren(document.activeElement)", completionHandler: nil)
                    }
                    
                    // For undo or other cases, check if we're in a text field
                    // Only needed for undo or edge cases since we handled common operations above
                    if keyCode == "z" {
                        // Just run the undo command directly
                        self.webView.evaluateJavaScript("document.execCommand('undo')", completionHandler: nil)
                    }
                    
                    // Trigger JavaScript beep suppression in the background
                    self.webView.evaluateJavaScript("""
                        if (window.silenceBeep) {
                            window.silenceBeep();
                        }
                    """, completionHandler: nil)
                    
                    // Only consume the event if we're handling it for the web view
                    return nil
                }
                
                // Handle tab selection shortcuts
                if let number = Int(event.charactersIgnoringModifiers ?? ""), 
                   number >= 1 && number <= self.radioButtons.count {
                    let index = number - 1
                    self.radioButtons[index].state = .on
                    self.loadWebPage(at: index)
                    return nil // Event handled
                }
            }
            
            return event
        }
        
        // Set up a script message handler for paste events
        let userContentController = self.webView.configuration.userContentController
        userContentController.add(self, name: "pasteHandler")
        
        // Inject script to handle keyboard shortcuts and form behavior
        let keyboardScript = WKUserScript(source: """
            // Enhanced form and keyboard handling for Mac webviews
            (function() {
                // Create a silent audio context to prevent beep sounds
                try {
                    var AudioContext = window.AudioContext || window.webkitAudioContext;
                    var audioCtx = new AudioContext();
                    
                    // Create multiple oscillators and gain nodes for better suppression
                    var oscillators = [];
                    var gainNodes = [];
                    
                    // Create 3 different oscillators with different frequencies
                    for (var i = 0; i < 3; i++) {
                        var osc = audioCtx.createOscillator();
                        var gain = audioCtx.createGain();
                        
                        // Set different frequencies
                        osc.frequency.value = 100 + (i * 200);
                        
                        // Set gain to 0 (silent)
                        gain.gain.value = 0;
                        
                        // Connect oscillator to gain node and gain node to output
                        osc.connect(gain);
                        gain.connect(audioCtx.destination);
                        
                        // Start the oscillator
                        osc.start();
                        
                        // Store references
                        oscillators.push(osc);
                        gainNodes.push(gain);
                    }
                    
                    // Create a more aggressive silenceBeep function
                    window.silenceBeep = function() {
                        // Method 1: Create multiple oscillators of different frequencies
                        for (var i = 0; i < 3; i++) {
                            var oscillator = audioCtx.createOscillator();
                            oscillator.frequency.value = 100 + (i * 300);
                            oscillator.connect(gainNodes[0]);
                            oscillator.start();
                            oscillator.stop(audioCtx.currentTime + 0.02);
                        }
                        
                        // Method 2: Create a short sound with a volume ramp
                        var oscRamp = audioCtx.createOscillator();
                        var gainRamp = audioCtx.createGain();
                        
                        gainRamp.gain.value = 0;
                        oscRamp.connect(gainRamp);
                        gainRamp.connect(audioCtx.destination);
                        
                        oscRamp.start();
                        oscRamp.stop(audioCtx.currentTime + 0.03);
                        
                        // Method 3: Manipulate existing oscillators
                        for (var i = 0; i < oscillators.length; i++) {
                            // Briefly change the frequency to trigger audio processing
                            var oldFreq = oscillators[i].frequency.value;
                            oscillators[i].frequency.value = oldFreq + 1;
                            setTimeout(function(osc, freq) {
                                return function() {
                                    osc.frequency.value = freq;
                                };
                            }(oscillators[i], oldFreq), 10);
                        }
                    };
                    
                    // Call silenceBeep immediately to initialize audio system
                    window.silenceBeep();
                } catch(e) {
                    console.log('Could not initialize audio context for silencing beeps');
                    window.silenceBeep = function() {};
                }
                
                // Add aggressive event listeners to capture and prevent command key beeps
                document.addEventListener('keydown', function(e) {
                    // Check for any command key combinations - they often cause beeps
                    if (e.metaKey) {
                        // Always silence beeps for any command key
                        if (window.silenceBeep) {
                            window.silenceBeep();
                            window.silenceBeep();
                        }
                        
                        // For command+a, command+c, command+x, command+z, command+v keys - the most common beep sources
                        if (e.key === 'a' || e.key === 'c' || e.key === 'x' || e.key === 'v' || e.key === 'z') {
                            // If we're in an editable element, use even more aggressive prevention
                            if (document.activeElement && 
                               (document.activeElement.tagName === 'INPUT' || 
                                document.activeElement.tagName === 'TEXTAREA' || 
                                document.activeElement.isContentEditable)) {
                                
                                // Silence any beeps more aggressively for text elements
                                if (window.silenceBeep) {
                                    window.silenceBeep();
                                    window.silenceBeep();
                                    window.silenceBeep();
                                }
                                
                                // Prevent default behavior to avoid beeps
                                // Note: Swift will handle the actual copy/paste/etc operations
                                e.preventDefault();
                                e.stopPropagation();
                                return false;
                            }
                        }
                    }
                }, true);
                
                // Capture event during capture phase for maximum prevention power
                document.addEventListener('keydown', function(e) {
                    if (e.metaKey && (e.key === 'a' || e.key === 'c' || e.key === 'x' || e.key === 'v' || e.key === 'z')) {
                        // Play silent sound as early as possible
                        if (window.silenceBeep) {
                            window.silenceBeep();
                        }
                    }
                }, true);
                
                // Capture Enter key in inputs to prevent beep and trigger submission
                document.addEventListener('keydown', function(e) {
                    // Handle Command+V (paste)
                    if (e.metaKey && e.key === 'v') {
                        if (document.activeElement && 
                            (document.activeElement.tagName === 'INPUT' || 
                             document.activeElement.tagName === 'TEXTAREA' || 
                             document.activeElement.isContentEditable)) {
                            e.preventDefault(); // Prevent default paste to avoid duplication
                        }
                    }
                    
                    // Handle Enter key
                    if (e.key === 'Enter' && !e.shiftKey) {
                        var activeElement = document.activeElement;
                        
                        // Only process for input fields
                        if (activeElement && 
                            (activeElement.tagName === 'INPUT' || 
                             activeElement.tagName === 'TEXTAREA')) {
                            
                            // Play silent sound to prevent system beep
                            if (window.silenceBeep) {
                                window.silenceBeep();
                            }
                            
                            // For inputs in forms
                            if (activeElement.form) {
                                var submitButton = Array.from(activeElement.form.elements || []).find(function(el) {
                                    return (el.type === 'submit' || 
                                           (el.tagName === 'BUTTON' && el.type !== 'button' && el.type !== 'reset'));
                                });
                                
                                if (submitButton) {
                                    // Allow natural form submission by clicking the submit button
                                    setTimeout(function() {
                                        submitButton.click();
                                    }, 0);
                                    e.preventDefault();
                                    return false;
                                } else if (activeElement.tagName === 'INPUT' && 
                                          activeElement.type !== 'textarea' && 
                                          activeElement.type !== 'submit' && 
                                          activeElement.type !== 'button') {
                                    // For single-line inputs in forms with no submit button
                                    try {
                                        // Try to submit the form programmatically
                                        var event = new Event('submit', { bubbles: true, cancelable: true });
                                        var submitted = activeElement.form.dispatchEvent(event);
                                        
                                        if (submitted) {
                                            // If the submit event wasn't prevented, submit the form
                                            setTimeout(function() {
                                                activeElement.form.submit();
                                            }, 0);
                                            e.preventDefault();
                                            return false;
                                        }
                                    } catch (err) {
                                        // Form submission failed, just let the default behavior happen
                                        console.log('Form submission error:', err);
                                    }
                                }
                            } 
                            // For standalone inputs (not in forms)
                            else if (activeElement.tagName === 'INPUT' && 
                                    activeElement.type !== 'textarea' && 
                                    activeElement.type !== 'submit' && 
                                    activeElement.type !== 'button') {
                                
                                // Trigger change event on input
                                var changeEvent = new Event('change', { bubbles: true, cancelable: true });
                                activeElement.dispatchEvent(changeEvent);
                                
                                // Look for an element with a click handler up the tree
                                var parent = activeElement.parentElement;
                                var maxDepth = 5; // Don't go too far up the tree
                                var depth = 0;
                                
                                while (parent && depth < maxDepth) {
                                    // Check for elements that might be handling the enter key
                                    if (parent.onclick || 
                                        parent.getAttribute('onclick') || 
                                        parent.onkeydown || 
                                        parent.onkeypress) {
                                        
                                        // Try to trigger a click on this parent
                                        setTimeout(function() {
                                            parent.click();
                                        }, 0);
                                        break;
                                    }
                                    parent = parent.parentElement;
                                    depth++;
                                }
                                
                                // Blur the input (losing focus often triggers submission in many UIs)
                                setTimeout(function() {
                                    activeElement.blur();
                                }, 10);
                                
                                // Prevent default to avoid beep
                                e.preventDefault();
                                return false;
                            }
                        }
                    }
                }, true);
                
                // Initialize the silent sound
                setTimeout(function() {
                    if (window.silenceBeep) {
                        window.silenceBeep();
                    }
                }, 500);
            })();
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        userContentController.addUserScript(keyboardScript)
    }
    
    // Handle copy operation
    private func handleCopy() {
        webView.evaluateJavaScript("""
            var selectedText = '';
            if (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'TEXTAREA') {
                selectedText = document.activeElement.value.substring(
                    document.activeElement.selectionStart, 
                    document.activeElement.selectionEnd
                );
            } else if (window.getSelection) {
                selectedText = window.getSelection().toString();
            }
            selectedText;
        """) { (result, error) in
            if let selectedText = result as? String, !selectedText.isEmpty {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(selectedText, forType: .string)
            }
        }
    }
    
    // Handle paste operation
    private func handlePaste() {
        let pasteboard = NSPasteboard.general
        if let clipboardContent = pasteboard.string(forType: .string) {
            // Escape quotes in the string to avoid JavaScript errors
            let escapedString = clipboardContent.replacingOccurrences(of: "\\", with: "\\\\")
                                              .replacingOccurrences(of: "'", with: "\\'")
                                              .replacingOccurrences(of: "\"", with: "\\\"")
                                              .replacingOccurrences(of: "\n", with: "\\n")
                                              .replacingOccurrences(of: "\r", with: "\\r")
            
            // Insert the text at the current cursor position
            webView.evaluateJavaScript("""
                (function() {
                    var activeElement = document.activeElement;
                    var text = "\(escapedString)";
                    
                    if (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA') {
                        var start = activeElement.selectionStart;
                        var end = activeElement.selectionEnd;
                        var value = activeElement.value;
                        
                        activeElement.value = value.substring(0, start) + text + value.substring(end);
                        activeElement.selectionStart = activeElement.selectionEnd = start + text.length;
                        
                        // Trigger input event for reactivity
                        var event = new Event('input', { bubbles: true });
                        activeElement.dispatchEvent(event);
                        
                        return true;
                    } else if (document.queryCommandSupported('insertText')) {
                        document.execCommand('insertText', false, text);
                        return true;
                    }
                    return false;
                })();
            """) { (result, error) in
                if let success = result as? Bool, !success {
                    // Fallback method if the above fails
                    self.webView.evaluateJavaScript("document.execCommand('paste')", completionHandler: nil)
                }
            }
        }
    }
    
    // Handle cut operation
    private func handleCut() {
        // First copy the selected text
        handleCopy()
        
        // Then delete the selected text
        webView.evaluateJavaScript("""
            if (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'TEXTAREA') {
                var start = document.activeElement.selectionStart;
                var end = document.activeElement.selectionEnd;
                var value = document.activeElement.value;
                
                document.activeElement.value = value.substring(0, start) + value.substring(end);
                document.activeElement.selectionStart = document.activeElement.selectionEnd = start;
                
                // Trigger input event for reactivity
                var event = new Event('input', { bubbles: true });
                document.activeElement.dispatchEvent(event);
            } else {
                document.execCommand('delete');
            }
        """, completionHandler: nil)
    }
    
    // Play a silent sound to prevent system beeps - optimized for speed
    private func playSilentSound() {
        // Use a single silent sound for most cases - this is faster
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.0
            sound.play()
        }
        
        // Call the JavaScript silencer in parallel
        self.webView.evaluateJavaScript("if (window.silenceBeep) { window.silenceBeep(); }", completionHandler: nil)
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Handle page load completion if needed

        // Get the title of the page if available
        if let title = webView.title, !title.isEmpty {
            // Update window title if needed
            view.window?.title = title
        }

        // Focus the first text input field on the page
        focusFirstTextbox()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Handle page load errors
        print("Navigation failed: \(error.localizedDescription)")
    }
}

// Add WKScriptMessageHandler to handle JavaScript messages
extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "pasteHandler" {
            // Handle paste from JavaScript
            handlePaste()
        }
    }
}

// Add WKUIDelegate to handle additional web view interactions
extension WebViewController: WKUIDelegate {
    // Handle JavaScript alerts
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = "Alert"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }
    
    // Handle JavaScript confirmations
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Confirm"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }
    
    // Handle JavaScript text input
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = NSAlert()
        alert.messageText = prompt
        
        // Use NSTextField with proper configuration for shortcuts
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        input.stringValue = defaultText ?? ""
        input.isEditable = true
        input.isSelectable = true
        input.allowsEditingTextAttributes = true
        input.usesSingleLineMode = true
        
        // Configure field editor when it becomes active
        NotificationCenter.default.addObserver(forName: NSControl.textDidBeginEditingNotification, object: input, queue: .main) { _ in
            if let fieldEditor = alert.window.fieldEditor(true, for: input) as? NSTextView {
                fieldEditor.allowsUndo = true
            }
        }
        
        alert.accessoryView = input
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        // Make the input field the first responder when the alert appears
        alert.window.makeFirstResponder(input)
        
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn ? input.stringValue : nil)
    }
    
    // Handle new windows/tabs
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Open the link in the same window instead of creating a new one
        if let targetFrame = navigationAction.targetFrame, !targetFrame.isMainFrame {
            webView.load(navigationAction.request)
        }
        return nil
    }
}