import SwiftUI
import Combine

// Helper for handling keyboard events at the app level
class KeyboardHandler: ObservableObject {
    @Published var pressedKeys: Set<String> = []
    
    private var cancellables = Set<AnyCancellable>()
    private var activeMonitors: [Any] = []
    
    init() {
        NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)
            .compactMap { $0.object as? NSWindow }
            .sink { [weak self] window in
                self?.monitorKeyEvents(window: window)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        // Clean up any remaining monitors
        for monitor in activeMonitors {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    func monitorKeyEvents(window: NSWindow) {
        // Remove any existing monitors
        for monitor in activeMonitors {
            NSEvent.removeMonitor(monitor)
        }
        activeMonitors.removeAll()
        
        // Add a new monitor
        let monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            if event.type == .keyDown {
                if let key = event.characters {
                    self?.pressedKeys.insert(key)
                }
                // Handle function keys by keycode
                if let specialKey = self?.specialKeyName(for: event.keyCode) {
                    self?.pressedKeys.insert(specialKey)
                }
            } else if event.type == .keyUp {
                if let key = event.characters {
                    self?.pressedKeys.remove(key)
                }
                if let specialKey = self?.specialKeyName(for: event.keyCode) {
                    self?.pressedKeys.remove(specialKey)
                }
            }
            return event
        }
        
        // Store the monitor in our own array
        if let localMonitor = monitor {
            activeMonitors.append(localMonitor)
        }
    }
    
    private func specialKeyName(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 123: return "leftArrow"
        case 124: return "rightArrow"
        case 125: return "downArrow"
        case 126: return "upArrow"
        case 36: return "return"
        case 49: return "space"
        case 53: return "escape"
        default: return nil
        }
    }
} 