public import SwiftUI
import SidePanePage

public struct RootPage: View {
    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidePanePage(selection: $selectedURL)
        } content: {

        } detail: {

        }
    }

    // MARK: - impl
    @State private var selectedURL: URL?
}

#Preview {
    RootPage()
}
