import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

private protocol HasAttributesSyntax: DeclSyntaxProtocol {
    var attributes: AttributeListSyntax { get }
}

extension MacroDeclSyntax: HasAttributesSyntax {}
extension ExtensionDeclSyntax: HasAttributesSyntax {}
extension ProtocolDeclSyntax: HasAttributesSyntax {}
extension ActorDeclSyntax: HasAttributesSyntax {}
extension ClassDeclSyntax: HasAttributesSyntax {}
extension EnumDeclSyntax: HasAttributesSyntax {}
extension StructDeclSyntax: HasAttributesSyntax {}
extension InitializerDeclSyntax: HasAttributesSyntax {}
extension FunctionDeclSyntax: HasAttributesSyntax {}
extension VariableDeclSyntax: HasAttributesSyntax {}
extension SubscriptDeclSyntax: HasAttributesSyntax {}
extension TypeAliasDeclSyntax: HasAttributesSyntax {}
extension AssociatedTypeDeclSyntax: HasAttributesSyntax {}

// MARK: -

class SyntaxFilter: SyntaxRewriter {
    enum Platform: Hashable {
        case ios, macos, tvos, watchos, visionos
        case maccatalyst
    }
    struct VersionRange: Hashable {
        var lower: String?
        var upper: String?

        init(_ range: Range<String>) {
            lower = range.lowerBound
            upper = range.upperBound
        }

        init(_ range: PartialRangeFrom<String>) {
            lower = range.lowerBound
        }

        init(_ range: PartialRangeUpTo<String>) {
            upper = range.upperBound
        }

        init?(min: String, max: String) {
            guard !min.isEmpty || !max.isEmpty else { return nil }
            lower = min.isEmpty ? nil : min
            upper = max.isEmpty ? nil : max
        }

        func contains(_ other: String) -> Bool {
            func compare(_ lhs: String?, fallback: ComparisonResult? = nil) -> ComparisonResult? {
                guard let lhs else { return fallback }
                return lhs.localizedStandardCompare(other)
            }

            // lower <= other < upper
            return compare(lower) != .orderedDescending
                && compare(upper, fallback: .orderedDescending) == .orderedDescending
        }
    }

    let conditions: [Platform: VersionRange]

    init?(conditions: [Platform: VersionRange?]) {
        guard case let conditions = conditions.compactMapValues(\.self),
              !conditions.isEmpty else {
            return nil
        }
        self.conditions = conditions
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: MacroDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    override func visit(_ node: AssociatedTypeDeclSyntax) -> DeclSyntax {
        filter(node, fallback: super.visit)
    }

    // MARK: - impl

    private struct State {
        var inAvailabilityLevel = 0
    }

    private var state = State()

    private func filter<T: HasAttributesSyntax>(_ node: T, fallback: (T) -> DeclSyntax) -> DeclSyntax {
        let incr = checkAvailability(node) ? 1 : 0
        state.inAvailabilityLevel += incr
        defer { state.inAvailabilityLevel -= incr }

        let curr = state.inAvailabilityLevel

        if incr > 0 {
            return DeclSyntax(node)
        } else {
            let walked = fallback(node)
            if state.inAvailabilityLevel > curr {
                return walked
            } else {
                return DeclSyntax(EditorPlaceholderDeclSyntax(placeholder: ""))
            }
        }
    }

    private func checkAvailability(_ node: some HasAttributesSyntax) -> Bool {
        let attributes = node.attributes.compactMap { attribute in
            switch attribute {
            case .attribute(let attr):
                return attr.arguments?.as(AvailabilityArgumentListSyntax.self)

            default:
                return nil
            }
        }

        guard !attributes.isEmpty else { return false }

        func checkArguments(_ arg: AvailabilityArgumentListSyntax.Element) -> Bool {
            guard case .availabilityVersionRestriction(let availability) = arg.argument,
                  let version = availability.version else { return false }

            let platform = availability.platform
            let targetPlatform = platform.trimmed.text
            let targetVersion = "\(version.major.trimmed.text)\(version.components.trimmedDescription)"

            func checkConditions() -> Bool {
                for (platform, version) in conditions {
                    if platform.value == targetPlatform, version.contains(targetVersion) {
                        return true
                    }
                }
                return conditions.isEmpty
            }

            return checkConditions()
        }

        return attributes.contains(where: { argments in
            argments.contains(where: { argment in checkArguments(argment) })
        })
    }
}

extension SyntaxFilter {
    static func filter(conditions: [Platform: VersionRange?], from source: String) throws -> String {
        guard let filter = SyntaxFilter(conditions: conditions) else {
            return source
        }

        let syntax = Parser.parse(source: source)
        let result = filter.rewrite(syntax)

        return String(bytes: result.syntaxTextBytes, encoding: .utf8) ?? ""
    }
}

// MARK: -

private extension SyntaxFilter.Platform {
    var value: String {
        switch self {
        case .ios: "iOS"
        case .macos: "macOS"
        case .tvos: "tvOS"
        case .watchos: "watchOS"
        case .visionos: "visionOS"
        case .maccatalyst: "macCatalyst"
        }
    }
}

// MARK: - Playground
import Playgrounds

#Playground {
    // swiftlint:disable:next line_length
    let url = URL(filePath: "/Applications/Xcode-26.0.0-Beta.2.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/SwiftData.framework/Modules/SwiftData.swiftmodule/arm64e-apple-ios.swiftinterface")
    let content = try String(contentsOf: url, encoding: .utf8)

    let syntax = Parser.parse(source: content)
    let result = SyntaxFilter(
        conditions: [.ios: .init("26"...)]
    )?.rewrite(syntax)

    let output = String(bytes: result?.syntaxTextBytes ?? [], encoding: .utf8)

    _ = output
}
