import SwiftUI

struct TimestampLabel: View {
    let date: Date

    var body: some View {
        Label(date.shortRelativeString, systemImage: "clock")
            .font(.caption2.weight(.medium))
            .foregroundStyle(IslandStyle.tertiaryText)
    }
}
