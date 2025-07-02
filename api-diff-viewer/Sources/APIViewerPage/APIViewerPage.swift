public import SwiftUI
public import Domain
import WebKit

public struct APIViewerPage: View {
    public init(
        swiftinterfacePath: URL,
        platform: Platform,
        filterMinVersion: String,
        filterMaxVersion: String
    ) {
        self.swiftinterfacePath = swiftinterfacePath
        self.platform = platform
        self.filterMinVersion = filterMinVersion
        self.filterMaxVersion = filterMaxVersion
    }

    public var body: some View {
        content()
            .id(swiftinterfacePath)
    }

    // MARK: - impl
    private let swiftinterfacePath: URL
    private let platform: Platform
    private let filterMinVersion: String
    private let filterMaxVersion: String

    @ViewBuilder
    private func content() -> some View {
        // swiftlint:disable switch_case_alignment
        let platform: SyntaxFilter.Platform = switch platform {
            case .iOS(nil), .iOS(.simulator): .ios
            case .macOS: .macos
            case .tvOS: .tvos
            case .watchOS: .watchos
            case .visionOS: .visionos
            case .iOS(.macCatalyst): .maccatalyst
        }
        // swiftlint:enable switch_case_alignment

        WebView(
            swiftinterfacePath: swiftinterfacePath,
            conditions: [
                platform: .init(min: filterMinVersion, max: filterMaxVersion)
            ]
        )
    }

    private struct AvailableEditView: View {
        @Binding var minText: String
        @Binding var maxText: String

        @State var editingMinText: String = ""
        @State var editingMaxText: String = ""

        @Environment(\.dismiss) var dismiss

        init(minText: Binding<String>, maxText: Binding<String>) {
            _minText = minText
            _maxText = maxText

            editingMinText = minText.wrappedValue
            editingMaxText = maxText.wrappedValue
        }

        var body: some View {
            VStack {
                HStack {
                    LabeledContent("Min") {
                        TextField("version", text: $editingMinText)
                    }
                    LabeledContent("Max") {
                        TextField("version", text: $editingMaxText)
                    }
                }

                Button("Apply") {
                    minText = editingMinText
                    maxText = editingMaxText
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .onAppear {
                editingMinText = minText
                editingMaxText = maxText
            }
        }
    }
}

private struct WebView: NSViewRepresentable {
    let swiftinterfacePath: URL
    let conditions: [SyntaxFilter.Platform: SyntaxFilter.VersionRange?]

    func makeNSView(context: Context) -> WKWebView {
        let webView = context.coordinator.webView

        let index = Bundle.module.url(forResource: "Resources/index", withExtension: "html")!
        webView.loadFileURL(index, allowingReadAccessTo: index)

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.loadContent(conditions: conditions)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(swiftinterfacePath: swiftinterfacePath, conditions: conditions)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        let swiftinterfacePath: URL
        let conditions: [SyntaxFilter.Platform: SyntaxFilter.VersionRange?]

        let webView = WKWebView()

        init(swiftinterfacePath: URL, conditions: [SyntaxFilter.Platform: SyntaxFilter.VersionRange?]) {
            self.swiftinterfacePath = swiftinterfacePath
            self.conditions = conditions
            super.init()

            webView.navigationDelegate = self
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loadContent(conditions: conditions)
        }

        func loadContent(conditions: [SyntaxFilter.Platform: SyntaxFilter.VersionRange?]) {
            Task.detached { [swiftinterfacePath] in
                let content = try String(contentsOf: swiftinterfacePath, encoding: .utf8)
                let filtered = try SyntaxFilter.filter(conditions: conditions, from: content)

                let escaped = try String(data: JSONEncoder().encode(filtered), encoding: .utf8) ?? ""

                let script = """
                function renewCodeSnippet() {
                    const container = document.getElementById("code-snippet");
                    if (container === null) {
                        return;
                    }
                    container.innerHTML = '';

                    const codeElem = document.createElement('code');
                    codeElem.textContent = \(escaped);

                    const pre = document.createElement('pre');
                    pre.appendChild(codeElem);
                    container.appendChild(pre);

                    hljs.highlightElement(codeElem);
                }

                renewCodeSnippet();
                """

                await self.runJavascript(script)
            }
        }

        @MainActor
        private func runJavascript(_ script: String) async {
            do {
                try await webView.evaluateJavaScript(script)
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    // swiftlint:disable:next line_length
    let path = URL(filePath: "/Applications/Xcode-26.0.0-Beta.2.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/_PermissionKit_UIKit.framework/Modules/_PermissionKit_UIKit.swiftmodule/arm64e-apple-ios.swiftinterface")

    APIViewerPage(
        swiftinterfacePath: path,
        platform: .iOS(),
        filterMinVersion: "",
        filterMaxVersion: ""
    )
    .frame(height: 500)
}
