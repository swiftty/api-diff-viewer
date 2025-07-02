public import SwiftUI
public import Domain

public struct SidePanePage: View {
    public init(
        platform: Platform,
        selection: Binding<URL?>
    ) {
        self.platform = platform
        _selection = selection
    }

    public var body: some View {
        content()
            .navigationSplitViewColumnWidth(min: 280, ideal: 280)
            .toolbar {
                if !items.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Open", systemImage: "tray.and.arrow.down") {
                            isFileImporterPresented = true
                        }
                    }
                }
            }
            .fileDialogDefaultDirectory(URL(filePath: "file:///Applications/"))
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.directory, .applicationBundle]
            ) { result in
                do {
                    let url = try result.get()
                    currentPath = url
                    items = try Operations.loadFrameworks(at: url, within: platform)
                } catch {
                    print(error)
                }
            }
            .onChange(of: platform) { _, newPlatform in
                do {
                    guard let url = currentPath else { return }
                    items = try Operations.loadFrameworks(at: url, within: newPlatform)
                } catch {
                    print(error)
                }
            }
    }

    // MARK: - impl
    struct Item: Hashable {
        var name: String
        var frameworkPath: URL
        var swiftInterfacePath: URL?
        var hasSwiftInterface: Bool { swiftInterfacePath != nil }
    }

    private let platform: Platform
    @Binding private var selection: URL?

    @State private var items: [Item] = []
    @State private var currentPath: URL?
    @State private var isFileImporterPresented: Bool = false

    @ViewBuilder
    private func content() -> some View {
        if items.isEmpty {
            ContentUnavailableView {
                Image(systemName: "tray.and.arrow.down")
            } description: {
                Text("Select a folder")
            } actions: {
                Button("Open") {
                    isFileImporterPresented = true
                }
            }
        } else {
            List(selection: $selection) {
                Section("Frameworks") {
                    ForEach(items, id: \.name) { item in
                        if item.hasSwiftInterface {
                            NavigationLink(value: item.swiftInterfacePath) {
                                cell(for: item)
                            }
                        } else {
                            cell(for: item)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }

    private func cell(for item: Item) -> some View {
        VStack(alignment: .leading) {
            Text("\(item.name).framework")
        }
        .foregroundStyle(item.hasSwiftInterface ? .primary : .secondary)
    }

    private enum Operations {
        static func loadFrameworks(at url: URL, within platform: Platform) throws -> [Item] {
            let targetPath = if url.lastPathComponent.contains("Xcode") {
                url.appending(path: "Contents/Developer/Platforms/\(platform.frameworksPath)")
            } else {
                url
            }

            var isDirectory: ObjCBool = false
            let fileManager = FileManager.default
            let isExists = fileManager.fileExists(atPath: targetPath.path(), isDirectory: &isDirectory)

            guard isExists, isDirectory.boolValue else { return [] }

            let frameworks = try fileManager.contentsOfDirectory(at: targetPath, includingPropertiesForKeys: nil)

            return try frameworks
                .map {
                    try toItem($0, with: fileManager)
                }
                .sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
        }

        private static func toItem(_ url: URL, with fileManager: FileManager) throws -> Item {
            let moduleName = url.lastPathComponent.components(separatedBy: ".")[0]
            let modulePath = url.appending(path: "Modules/\(moduleName).swiftmodule")

            func findSwiftInterfacePath() throws -> URL? {
                var isDirectory: ObjCBool = false
                let isExists = fileManager.fileExists(atPath: modulePath.path(), isDirectory: &isDirectory)
                guard isExists, isDirectory.boolValue else { return nil }

                for path in try fileManager.contentsOfDirectory(at: modulePath, includingPropertiesForKeys: nil)
                where path.pathExtension == "swiftinterface" {
                    return path
                }
                return nil
            }

            return Item(
                name: moduleName,
                frameworkPath: url,
                swiftInterfacePath: try findSwiftInterfacePath()
            )
        }
    }
}

extension Platform {
    private var value: String {
        switch self {
        case .iOS(nil), .iOS(.macCatalyst):
            "iPhoneOS"
        case .iOS:
            "iPhoneSimulator"
        case .macOS:
            "MacOSX"
        case .tvOS(nil):
            "AppleTVOS"
        case .tvOS(.simulator):
            "AppleTVSimulator"
        case .watchOS(nil):
            "WatchOS"
        case .watchOS(.simulator):
            "WatchSimulator"
        case .visionOS(nil):
            "XROS"
        case .visionOS(.simulator):
            "XRSimulator"
        }
    }

    var frameworksPath: String {
        let value = value
        return "\(value).platform/Developer/SDKs/\(value).sdk/System/Library/Frameworks"
    }
}

#Preview {
    @Previewable @State var selection: URL?

    NavigationSplitView {
        SidePanePage(platform: .iOS(), selection: $selection)
    } detail: {
        Text("Empty")
    }
}
