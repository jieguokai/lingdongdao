import SwiftUI

struct NotchShellShape: InsettableShape {
    var topEdgeExtension: CGFloat = 0
    var topTransitionRadius: CGFloat = 0
    var bottomCornerRadius: CGFloat = 14
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let bottomRadius = min(bottomCornerRadius, insetRect.width / 2, insetRect.height / 2)
        let extensionWidth = min(topEdgeExtension, insetRect.width / 2)
        let topLeft = insetRect.minX - extensionWidth
        let topRight = insetRect.maxX + extensionWidth

        var path = Path()
        path.move(to: CGPoint(x: topLeft, y: insetRect.minY))
        path.addLine(to: CGPoint(x: topRight, y: insetRect.minY))
        path.addLine(to: CGPoint(x: topRight, y: insetRect.minY))
        path.addLine(to: CGPoint(x: topRight, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - bottomRadius))
        path.addQuadCurve(
            to: CGPoint(x: insetRect.maxX - bottomRadius, y: insetRect.maxY),
            control: CGPoint(x: insetRect.maxX, y: insetRect.maxY)
        )
        path.addLine(to: CGPoint(x: insetRect.minX + bottomRadius, y: insetRect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: insetRect.minX, y: insetRect.maxY - bottomRadius),
            control: CGPoint(x: insetRect.minX, y: insetRect.maxY)
        )
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY))
        path.addLine(to: CGPoint(x: topLeft, y: insetRect.minY))
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
