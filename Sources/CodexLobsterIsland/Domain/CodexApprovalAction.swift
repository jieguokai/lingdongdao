import Foundation

package struct CodexApprovalAction: Identifiable, Equatable, Sendable, Codable {
    package enum Role: String, Codable, Sendable {
        case approve
        case reject
        case neutral
    }

    package let id: String
    package let label: String
    package let role: Role
    package let actionPayload: String

    package init(
        id: String = UUID().uuidString,
        label: String,
        role: Role,
        actionPayload: String
    ) {
        self.id = id
        self.label = label
        self.role = role
        self.actionPayload = actionPayload
    }
}
