import SwiftUI

struct MinimalToggleStyle: ToggleStyle {
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .foregroundStyle(IslandStyle.primaryText)

                Spacer(minLength: 8)

                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule(style: .continuous)
                        .fill(configuration.isOn ? accentColor.opacity(0.26) : Color.white.opacity(0.10))
                        .frame(width: 34, height: 20)

                    Circle()
                        .fill(Color.white.opacity(configuration.isOn ? 0.98 : 0.92))
                        .frame(width: 14, height: 14)
                        .padding(3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
