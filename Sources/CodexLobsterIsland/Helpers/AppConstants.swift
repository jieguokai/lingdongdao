import CoreGraphics

enum AppConstants {
    static let compactIslandContentSize = CGSize(width: 235, height: 28)
    static let expandedIslandContentSize = CGSize(width: 560, height: 320)
    static let compactIslandHoverSidePadding: CGFloat = 10
    static let expandedIslandHoverSidePadding: CGFloat = 8
    static let compactIslandSize = CGSize(
        width: compactIslandContentSize.width + (compactIslandHoverSidePadding * 2),
        height: compactIslandContentSize.height
    )
    static let expandedIslandSize = CGSize(
        width: expandedIslandContentSize.width + (expandedIslandHoverSidePadding * 2),
        height: expandedIslandContentSize.height
    )
    static let islandTopMargin: CGFloat = 0
}
