//
//  User.swift
//  RestAPI
//
//  Created by 김동현 on 7/23/25.
//

import Foundation

// MARK: – 도메인 모델
struct User: Codable {
    let id: String?       // Firestore 문서ID (읽을 때만 설정)
    let name: String
    var age: Int
}

// MARK: – Firestore 전송·수신용 DTO
struct UserDto: Codable {
    var name: String
    var age: Int
    
    // Firestore 문서ID는 DTO에 포함하지 않고, 읽을 때 별도 처리합니다.
    // MARK: — 모델 → DTO
    init(_ user: User) {
        self.name = user.name
        self.age  = user.age
    }
    
    // MARK: — DTO → 모델
    func toDomain(id: String? = nil) -> User {
        return User(id: id, name: name, age: age)
    }
}

// MARK: — Encodable → [String:Any] 헬퍼
extension Encodable {
    func toDictionary() throws -> [String:Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data) as? [String:Any]
        return json ?? [:]
    }
}
