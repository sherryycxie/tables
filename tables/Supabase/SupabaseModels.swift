import Foundation

// MARK: - Database DTOs (match Supabase schema)

struct SupabaseTable: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var title: String
    var context: String?
    var status: String
    var createdAt: Date
    var updatedAt: Date
    var members: [String]
    var nextReminderDate: Date?
    let ownerId: UUID

    enum CodingKeys: String, CodingKey {
        case id, title, context, status, members
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case nextReminderDate = "next_reminder_date"
        case ownerId = "owner_id"
    }
}

struct SupabaseCard: Codable, Identifiable, Sendable {
    let id: UUID
    let tableId: UUID
    var title: String?
    var body: String
    var linkUrl: String?
    var createdAt: Date
    var authorName: String
    var status: String

    enum CodingKeys: String, CodingKey {
        case id, title, body, status
        case tableId = "table_id"
        case linkUrl = "link_url"
        case createdAt = "created_at"
        case authorName = "author_name"
    }
}

struct SupabaseComment: Codable, Identifiable, Sendable {
    let id: UUID
    let cardId: UUID
    var body: String
    var createdAt: Date
    var authorName: String

    enum CodingKeys: String, CodingKey {
        case id, body
        case cardId = "card_id"
        case createdAt = "created_at"
        case authorName = "author_name"
    }
}

struct SupabaseNudge: Codable, Identifiable, Sendable {
    let id: UUID
    let tableId: UUID
    var createdAt: Date
    var authorName: String
    var message: String?

    enum CodingKeys: String, CodingKey {
        case id, message
        case tableId = "table_id"
        case createdAt = "created_at"
        case authorName = "author_name"
    }
}

struct SupabaseTableShare: Codable, Identifiable, Sendable {
    let id: UUID
    let tableId: UUID
    let sharedWithUserId: UUID
    var permission: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, permission
        case tableId = "table_id"
        case sharedWithUserId = "shared_with_user_id"
        case createdAt = "created_at"
    }
}

struct SupabaseProfile: Codable, Identifiable, Sendable {
    let id: UUID
    var email: String?
    var displayName: String?
    var firstName: String?
    var lastName: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
    }

    /// Returns the full name (first + last) or falls back to displayName
    var fullName: String? {
        if let first = firstName, !first.isEmpty {
            if let last = lastName, !last.isEmpty {
                return "\(first) \(last)"
            }
            return first
        }
        return displayName
    }
}

// MARK: - Insert DTOs (without id, letting database generate it)

struct InsertTable: Codable, Sendable {
    let id: UUID
    var title: String
    var context: String?
    var status: String
    var members: [String]
    var nextReminderDate: Date?
    let ownerId: UUID

    enum CodingKeys: String, CodingKey {
        case id, title, context, status, members
        case nextReminderDate = "next_reminder_date"
        case ownerId = "owner_id"
    }
}

struct InsertCard: Codable, Sendable {
    let id: UUID
    let tableId: UUID
    var title: String?
    var body: String
    var linkUrl: String?
    var authorName: String
    var status: String

    enum CodingKeys: String, CodingKey {
        case id, title, body, status
        case tableId = "table_id"
        case linkUrl = "link_url"
        case authorName = "author_name"
    }
}

struct InsertComment: Codable, Sendable {
    let id: UUID
    let cardId: UUID
    var body: String
    var authorName: String

    enum CodingKeys: String, CodingKey {
        case id, body
        case cardId = "card_id"
        case authorName = "author_name"
    }
}

struct InsertNudge: Codable, Sendable {
    let id: UUID
    let tableId: UUID
    var authorName: String
    var message: String?

    enum CodingKeys: String, CodingKey {
        case id, message
        case tableId = "table_id"
        case authorName = "author_name"
    }
}

struct InsertTableShare: Codable, Sendable {
    let tableId: UUID
    let sharedWithUserId: UUID
    var permission: String

    enum CodingKeys: String, CodingKey {
        case permission
        case tableId = "table_id"
        case sharedWithUserId = "shared_with_user_id"
    }
}

struct InsertProfile: Codable, Sendable {
    let id: UUID
    var email: String?
    var displayName: String
    var firstName: String?
    var lastName: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

// MARK: - Reflections

struct SupabaseReflection: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var body: String
    var prompt: String?
    var reflectionType: String
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, body, prompt
        case userId = "user_id"
        case reflectionType = "reflection_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct InsertReflection: Codable, Sendable {
    let id: UUID
    let userId: UUID
    var body: String
    var prompt: String?
    var reflectionType: String

    enum CodingKeys: String, CodingKey {
        case id, body, prompt
        case userId = "user_id"
        case reflectionType = "reflection_type"
    }
}
