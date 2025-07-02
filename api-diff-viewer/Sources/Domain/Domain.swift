import Foundation

public enum Platform: Hashable {
    case iOS(IOSOption? = nil)
    case macOS
    case tvOS(Option? = nil)
    case watchOS(Option? = nil)
    case visionOS(Option? = nil)

    public enum IOSOption: Hashable {
        case simulator
        case macCatalyst
    }

    public enum Option: Hashable {
        case simulator
    }
}
