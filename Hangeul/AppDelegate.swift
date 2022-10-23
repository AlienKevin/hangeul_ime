import Cocoa
import InputMethodKit

// Necessary to launch this app
class NSManualApplication: NSApplication {
    private let appDelegate = AppDelegate()

    override init() {
        super.init()
        self.delegate = appDelegate
    }

    required init?(coder: NSCoder) {
        // No need for implementation
        fatalError("init(coder:) has not been implemented")
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var state: State!
    
    func installInputSource() {
        print("install input source")
//        InputSource.shared.deactivateInputSource()
        InputSource.shared.registerInputSource()
        InputSource.shared.activateInputSource()
    }
    
    func stop() {
        InputSource.shared.deactivateInputSource()
        NSApp.terminate(nil)
    }
    
    private func commandHandler() -> Bool {
        if CommandLine.arguments.count > 1 {
            print("[Hangeul] launch argument: \(CommandLine.arguments[1])")
            let command = CommandLine.arguments[1]
            if command == "--install" {
                installInputSource()
                return false
            }
            if command == "--stop" {
                print("[Hangeul] stop")
                stop()
                return false
            }
        }
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !commandHandler() {
            return
        }
        
        state = State.shared
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Insert code here to tear down your application
    }
}
