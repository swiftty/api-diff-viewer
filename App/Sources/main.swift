import SwiftUI
import AppProvider

struct App {
    #if DEBUG
    private struct TestApp: SwiftUI.App {
        var body: some Scene {
            WindowGroup {
                Text("Now Testing...")
            }
        }
    }
    #endif

    static func main() {
        #if DEBUG
        if NSClassFromString("XCTestCase") != nil {
            TestApp.main()
            return
        }
        #endif

        AppProvider.App.main()
    }
}

App.main()
