public import SwiftUI
import WebKit

public struct APIViewerPage: View {
    public init(swiftinterfacePath: URL) {
        self.swiftinterfacePath = swiftinterfacePath
    }

    public var body: some View {
        content()
            .id(swiftinterfacePath)
    }

    // MARK: - impl
    private let swiftinterfacePath: URL

    private func content() -> some View {
        WebView(swiftinterfacePath: swiftinterfacePath)
    }
}

private struct WebView: NSViewRepresentable {
    let swiftinterfacePath: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = context.coordinator.webView

        let index = Bundle.module.url(forResource: "Resources/index", withExtension: "html")!
        webView.loadFileURL(index, allowingReadAccessTo: index)

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(swiftinterfacePath: swiftinterfacePath)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        let swiftinterfacePath: URL
        let webView = WKWebView()

        init(swiftinterfacePath: URL) {
            self.swiftinterfacePath = swiftinterfacePath
            super.init()

            webView.navigationDelegate = self
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task {
                do {
                    let content = try String(contentsOf: swiftinterfacePath, encoding: .utf8)
                    let filtered = try SyntaxFilter.filter(conditions: [.ios: .init("26"...)], from: content)

                    let escaped = try String(data: JSONEncoder().encode(filtered), encoding: .utf8) ?? ""

                    try await webView.evaluateJavaScript("""
                    const container = document.getElementById("code-snippet");
                    container.innerHTML = '';

                    const codeElem = document.createElement('code');
                    codeElem.textContent = \(escaped);

                    const pre = document.createElement('pre');
                    pre.appendChild(codeElem);
                    container.appendChild(pre);

                    hljs.highlightElement(codeElem);
                    """)
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    // swiftlint:disable:next line_length
    WebView(swiftinterfacePath: URL(filePath: "/Applications/Xcode-26.0.0-Beta.2.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/_PermissionKit_UIKit.framework/Modules/_PermissionKit_UIKit.swiftmodule/arm64e-apple-ios.swiftinterface"))
        .frame(height: 500)
}
