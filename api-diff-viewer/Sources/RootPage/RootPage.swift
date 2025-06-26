public import SwiftUI
import SidePanePage
import APIViewerPage

public struct RootPage: View {
    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidePanePage(selection: $selectedURL)
        } detail: {
            if let selectedURL {
                APIViewerPage(swiftinterfacePath: selectedURL)
            }
        }
    }

    // MARK: - impl
    @State private var selectedURL: URL?
}

#Preview {
    RootPage()
}
