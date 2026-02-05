// WordRoninApp.swift
import SwiftUI

@main
struct WordRoninApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootModeView()
        }
    }
}
