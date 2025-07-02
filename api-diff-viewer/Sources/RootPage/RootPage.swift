public import SwiftUI
import SidePanePage
import APIViewerPage
import Domain

public struct RootPage: View {
    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidePanePage(platform: selectedPlatform, selection: $selectedURL)
        } detail: {
            if let selectedURL {
                APIViewerPage(
                    swiftinterfacePath: selectedURL,
                    platform: selectedPlatform,
                    filterMinVersion: filterMinVersion,
                    filterMaxVersion: filterMaxVersion
                )
            }
        }
        .toolbar {
            ToolbarItem {
                Picker("Platform", selection: $selectedPlatform) {
                    ForEach(Platform.allCases, id: \.self) { platform in
                        Text(platform.name)
                            .tag(platform)
                    }
                }
            }

            ToolbarItem {
                Button {
                    showsAvailableFilter.toggle()
                } label: {
                    let version = [filterMinVersion, filterMaxVersion]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ~ ")
                    Text(version.isEmpty ? "Available" : "Available: \(version)")
                }
                .popover(isPresented: $showsAvailableFilter, arrowEdge: .bottom) {
                    AvailableFilterView(
                        minVersion: $filterMinVersion,
                        maxVersion: $filterMaxVersion
                    )
                }
            }
        }
    }

    // MARK: - impl
    @State private var selectedURL: URL?

    @State private var selectedPlatform: Platform = Platform.allCases[0]

    @State private var showsAvailableFilter = false
    @State private var filterMinVersion: String = ""
    @State private var filterMaxVersion: String = ""
}

private extension Platform {
    static var allCases: [Platform] {
        [
            .iOS(),
            .iOS(.simulator),
            .macOS,
            .watchOS(),
            .watchOS(.simulator),
            .tvOS(),
            .tvOS(.simulator),
            .visionOS(),
            .visionOS(.simulator),
            .iOS(.macCatalyst)
        ]
    }

    var name: String {
        switch self {
        case .iOS(nil):
            "iOS"
        case .iOS(.simulator):
            "iOS Simulator"
        case .iOS(.macCatalyst):
            "macCatalyst"
        case .macOS:
            "macOS"
        case .tvOS(nil):
            "tvOS"
        case .tvOS(.simulator):
            "tvOS Simulator"
        case .watchOS(nil):
            "watchOS"
        case .watchOS(.simulator):
            "watchOS Simulator"
        case .visionOS(nil):
            "visionOS"
        case .visionOS(.simulator):
            "visionOS Simulator"
        }
    }
}

#Preview {
    RootPage()
}
