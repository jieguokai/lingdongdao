import SwiftUI

struct NotchShellShape: InsettableShape {
    var topCornerRadius: CGFloat = 7
    var bottomCornerRadius: CGFloat = 12
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let topRadius = min(topCornerRadius, insetRect.width / 2, insetRect.height / 2)
        let bottomRadius = min(bottomCornerRadius, insetRect.width / 2, insetRect.height / 2)

        var path = Path()
        path.move(to: CGPoint(x: insetRect.minX + topRadius, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX - topRadius, y: insetRect.minY))
        path.addQuadCurve(
            to: CGPoint(x: insetRect.maxX, y: insetRect.minY + topRadius),
            control: CGPoint(x: insetRect.maxX, y: insetRect.minY)
        )
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
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY + topRadius))
        path.addQuadCurve(
            to: CGPoint(x: insetRect.minX + topRadius, y: insetRect.minY),
            control: CGPoint(x: insetRect.minX, y: insetRect.minY)
        )
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
