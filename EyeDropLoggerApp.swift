import SwiftUI

@main
struct EyeDropLoggerApp: App {
    @StateObject private var store = DataStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
