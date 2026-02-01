import Foundation
import SwiftData

enum ReflectionType: String, Codable {
    case quickWin = "quick_win"
    case deepReflection = "deep_reflection"
}

@Model
final class ReflectionModel {
    var id: UUID
    var body: String
    var prompt: String?
    var reflectionType: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        body: String,
        prompt: String? = nil,
        reflectionType: ReflectionType,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.body = body
        self.prompt = prompt
        self.reflectionType = reflectionType.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var type: ReflectionType {
        ReflectionType(rawValue: reflectionType) ?? .quickWin
    }
}
