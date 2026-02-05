import SwiftUI

@main
struct slicenspellApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootModeView()
        }
    }
}
