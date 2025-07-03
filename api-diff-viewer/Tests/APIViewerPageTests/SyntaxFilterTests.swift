import Testing

@testable import APIViewerPage

// swiftlint:disable line_length
struct SyntaxFilterTests {
    @Test
    func `versionRange comparation`() throws {
        do {
            let input = SyntaxFilter.VersionRange("26"...)
            #expect(input.contains("26"))
            #expect(input.contains("100"))
            #expect(!input.contains("25"))
            #expect(!input.contains("25.9"))
        }
        do {
            let input = SyntaxFilter.VersionRange("26"..<"27")
            #expect(input.contains("26"))
            #expect(input.contains("26.9"))
            #expect(!input.contains("27"))
            #expect(!input.contains("25"))
            #expect(!input.contains("25.9"))
        }
    }

    @Test
    func `can filter with decimal point`() throws {
        let input = """
        // swift-interface-format-version: 1.0
        // swift-compiler-version: Apple Swift version 6.2 effective-5.10 (swiftlang-6.2.0.10.905 clang-1700.3.10.902)
        // swift-module-flags: -target arm64e-apple-ios26.0 -enable-objc-interop -enable-library-evolution -swift-version 5 -enforce-exclusivity=checked -O -library-level api -enable-upcoming-feature InternalImportsByDefault -enable-upcoming-feature MemberImportVisibility -enable-experimental-feature DebugDescriptionMacro -enable-bare-slash-regex -user-module-version 60.28 -module-name SecureElementCredential
        // swift-module-flags-ignorable:  -formal-cxx-interoperability-mode=off -interface-compiler-version 6.2
        public import Foundation
        public import Swift
        public import _Concurrency
        public import _StringProcessing
        public import _SwiftConcurrencyShims
        @available(iOS 18.1, *)
        @available(macOS, unavailable)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        @available(visionOS, unavailable)
        public actor CredentialSession : Swift.Equatable {
          @objc deinit
        }
        """

        let expected = """
        // swift-interface-format-version: 1.0
        // swift-compiler-version: Apple Swift version 6.2 effective-5.10 (swiftlang-6.2.0.10.905 clang-1700.3.10.902)
        // swift-module-flags: -target arm64e-apple-ios26.0 -enable-objc-interop -enable-library-evolution -swift-version 5 -enforce-exclusivity=checked -O -library-level api -enable-upcoming-feature InternalImportsByDefault -enable-upcoming-feature MemberImportVisibility -enable-experimental-feature DebugDescriptionMacro -enable-bare-slash-regex -user-module-version 60.28 -module-name SecureElementCredential
        // swift-module-flags-ignorable:  -formal-cxx-interoperability-mode=off -interface-compiler-version 6.2
        public import Foundation
        public import Swift
        public import _Concurrency
        public import _StringProcessing
        public import _SwiftConcurrencyShims
        """

        let filter = try SyntaxFilter.filter(conditions: [.ios: .init("26"...)], from: input)
        #expect(filter == expected)
    }
}

// swiftlint:enable line_length
