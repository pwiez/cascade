import SwiftUI
import TipKit

@main
struct Cascade: App {    
    init() {
        try? Tips.resetDatastore()
        
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
