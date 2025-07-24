//
//  Todo.swift
//  RestAPI
//
//  Created by 김동현 on 7/25/25.
//

import Foundation

// MARK: — 도메인 모델
struct Todo: Identifiable {
    let id: Int
    var title: String
    var isDone: Bool
    var createdAt: Date
    var updatedAt: Date
}

// MARK: — DTO: API <→→→> Swift
struct TodoDto: Codable {
    let id: Int
    let title: String
    let isDone: Bool
    let createdAt: String
    let updatedAt: String

    // JSON 키 매핑
    enum CodingKeys: String, CodingKey {
        case id, title
        case isDone     = "is_done"
        case createdAt  = "created_at"
        case updatedAt  = "updated_at"
    }

    // DTO → 도메인 모델 변환
    func toDomain() -> Todo {
        let formatter = ISO8601DateFormatter()
        return Todo(
            id: id,
            title: title,
            isDone: isDone,
            createdAt: formatter.date(from: createdAt) ?? .distantPast,
            updatedAt: formatter.date(from: updatedAt) ?? .distantPast
        )
    }

    // 도메인 모델 → DTO 변환
    init(fromDomain todo: Todo) {
        let formatter = ISO8601DateFormatter()
        self.id         = todo.id
        self.title      = todo.title
        self.isDone     = todo.isDone
        self.createdAt  = formatter.string(from: todo.createdAt)
        self.updatedAt  = formatter.string(from: todo.updatedAt)
    }
}
