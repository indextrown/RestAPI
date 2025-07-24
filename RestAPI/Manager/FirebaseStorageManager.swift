//
//  FirebaseStorageManager.swift
//  RestAPI
//
//  Created by 김동현 on 7/23/25.
//

import Combine
import Foundation
import FirebaseFirestore


final class FirestoreManager {
    
    static let shared = FirestoreManager()
    private init() {}
    
    private let db = Firestore.firestore()
}

// MARK: - 기본적인 CRUD
extension FirestoreManager {
    // MARK: - Create
    func createDocument(collection: String, data: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        var ref: DocumentReference? = nil
        ref = db.collection(collection).addDocument(data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else if let documentID = ref?.documentID {
                completion(.success(documentID))
            }
        }
    }
    
    // MARK: - Read
    func readDocument(collection: String, documentID: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection(collection).document(documentID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = snapshot?.data() {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "문서를 찾을 수 없습니다."])))
            }
        }
    }
    
    // MARK: - Update
    func updateDocument(collection: String, documentID: String, data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(collection).document(documentID).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Delete
    func deleteDocument(collection: String, documentID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(collection).document(documentID).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

// MARK: - 제네릭 CRUD
extension FirestoreManager {
    
    // MARK: - Create
    func createGenericDocument<T: Encodable>(
        collection: String,
        object: T,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        do {
            let data = try JSONEncoder().encode(object)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            var ref: DocumentReference? = nil
            ref = db.collection(collection).addDocument(data: dict) { error in
                if let error = error {
                    completion(.failure(error))
                } else if let id = ref?.documentID {
                    completion(.success(id))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Read (단일 문서)
    func readGenericDocument<T: Decodable>(
        collection: String,
        documentID: String,
        as type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let docRef = db.collection(collection).document(documentID)
        docRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard
                let data = snapshot?.data(),
                let jsonData = try? JSONSerialization.data(withJSONObject: data),
                let object = try? JSONDecoder().decode(T.self, from: jsonData)
            else {
                completion(.failure(NSError(
                    domain: "FirestoreManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "디코딩 실패"]
                )))
                return
            }
            completion(.success(object))
        }
    }
    
    // MARK: - Read (컬렉션 전체)
    func readGenericCollection<T: Decodable>(
        collection: String,
        as type: T.Type,
        completion: @escaping (Result<[T], Error>) -> Void
    ) {
        db.collection(collection).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            let result: [T] = documents.compactMap { doc in
                guard
                    let jsonData = try? JSONSerialization.data(withJSONObject: doc.data()),
                    let object = try? JSONDecoder().decode(T.self, from: jsonData)
                else { return nil }
                return object
            }
            completion(.success(result))
        }
    }
    
    // MARK: - Update
    func updateGenericDocument<T: Encodable>(
        collection: String,
        documentID: String,
        with object: T,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            let data = try JSONEncoder().encode(object)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            db.collection(collection)
              .document(documentID)
              .setData(dict, merge: true) { error in
                  if let error = error {
                      completion(.failure(error))
                  } else {
                      completion(.success(()))
                  }
              }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Delete
    func deleteGenericDocument(
        collection: String,
        documentID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection(collection)
          .document(documentID)
          .delete { error in
              if let error = error {
                  completion(.failure(error))
              } else {
                  completion(.success(()))
              }
          }
    }
}

// MARK: – Combine Publishers
extension FirestoreManager {
    
    /// 생성: Encodable 객체를 Firestore에 추가하고 Document ID를 방출
    /// - Parameters:
    ///   - collection: 컬렉션 이름
    ///   - object: 전송할 DTO (Encodable)
    /// - Returns: 새로 생성된 문서 ID를 방출하는 AnyPublisher<String, Error>
    func createGenericPublisher<T: Encodable>(
        collection: String,
        object: T
    ) -> AnyPublisher<String, Error> {
        Future<String, Error> { promise in
            self.createGenericDocument(collection: collection, object: object) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 단일 조회: 지정한 Document ID의 DTO를 디코딩하여 방출
    /// - Parameters:
    ///   - collection: 컬렉션 이름
    ///   - documentID: 읽어올 문서의 ID
    ///   - type: Decodable 타입
    /// - Returns: 디코딩된 DTO를 방출하는 AnyPublisher<T, Error>
    func readGenericPublisher<T: Decodable>(
        collection: String,
        documentID: String,
        as type: T.Type
    ) -> AnyPublisher<T, Error> {
        Future<T, Error> { promise in
            self.readGenericDocument(collection: collection, documentID: documentID, as: type) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 컬렉션 조회: 전체 문서를 DTO 배열로 디코딩하여 방출
    /// - Parameter collection: 컬렉션 이름
    /// - Parameter type: Decodable 타입
    /// - Returns: 디코딩된 DTO 배열을 방출하는 AnyPublisher<[T], Error>
    func readGenericCollectionPublisher<T: Decodable>(
        collection: String,
        as type: T.Type
    ) -> AnyPublisher<[T], Error> {
        Future<[T], Error> { promise in
            self.readGenericCollection(collection: collection, as: type) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 업데이트: Encodable DTO를 Firestore에 덮어쓰고 완료를 방출
    /// - Parameters:
    ///   - collection: 컬렉션 이름
    ///   - documentID: 업데이트할 문서 ID
    ///   - object: 업데이트 내용 DTO (Encodable)
    /// - Returns: 완료 시 Void를 방출하는 AnyPublisher<Void, Error>
    func updateGenericPublisher<T: Encodable>(
        collection: String,
        documentID: String,
        with object: T
    ) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            self.updateGenericDocument(collection: collection, documentID: documentID, with: object) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 삭제: 지정한 Document ID를 삭제하고 완료를 방출
    /// - Parameters:
    ///   - collection: 컬렉션 이름
    ///   - documentID: 삭제할 문서 ID
    /// - Returns: 완료 시 Void를 방출하는 AnyPublisher<Void, Error>
    func deleteGenericPublisher(
        collection: String,
        documentID: String
    ) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            self.deleteGenericDocument(collection: collection, documentID: documentID) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: – Combine Publishers (toCombine() 사용)
// MARK: -  기존 completion(Result<T,Error>) 클로저를 Future 기반 AnyPublisher로 래핑하는 헬퍼
extension FirestoreManager {
    /// completion(Result<T,Error>) 클로저를 Future 기반 AnyPublisher로 래핑
    private func toCombine<T>(
        _ work: @escaping (@escaping (Result<T, Error>) -> Void) -> Void
    ) -> AnyPublisher<T, Error> {
        Future<T, Error> { promise in
            work { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 생성 퍼블리셔
    func createGenericPublisher2<T: Encodable>(
        collection: String,
        object: T
    ) -> AnyPublisher<String, Error> {
        toCombine { completion in
            self.createGenericDocument(
                collection: collection,
                object: object,
                completion: completion
            )
        }
    }
    
    /// 단일 조회 퍼블리셔
    func readGenericPublisher2<T: Decodable>(
        collection: String,
        documentID: String,
        as type: T.Type
    ) -> AnyPublisher<T, Error> {
        toCombine { completion in
            self.readGenericDocument(
                collection: collection,
                documentID: documentID,
                as: type,
                completion: completion
            )
        }
    }
    
    /// 컬렉션 조회 퍼블리셔
    func readGenericCollectionPublisher2<T: Decodable>(
        collection: String,
        as type: T.Type
    ) -> AnyPublisher<[T], Error> {
        toCombine { completion in
            self.readGenericCollection(
                collection: collection,
                as: type,
                completion: completion
            )
        }
    }
    
    /// 업데이트 퍼블리셔
    func updateGenericPublisher2<T: Encodable>(
        collection: String,
        documentID: String,
        with object: T
    ) -> AnyPublisher<Void, Error> {
        toCombine { completion in
            self.updateGenericDocument(
                collection: collection,
                documentID: documentID,
                with: object,
                completion: completion
            )
        }
    }
    
    /// 삭제 퍼블리셔
    func deleteGenericPublisher2(
        collection: String,
        documentID: String
    ) -> AnyPublisher<Void, Error> {
        toCombine { completion in
            self.deleteGenericDocument(
                collection: collection,
                documentID: documentID,
                completion: completion
            )
        }
    }
}








/*
final class FirestoreManager {
    private let db = Firestore.firestore()
    
    // MARK: - Create
    func createDocument(collection: String, data: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        var ref: DocumentReference? = nil
        ref = db.collection(collection).addDocument(data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else if let documentID = ref?.documentID {
                completion(.success(documentID))
            }
        }
    }
    
    // MARK: - Read
    func readDocument(collection: String, documentID: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection(collection).document(documentID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = snapshot?.data() {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "문서를 찾을 수 없습니다."])))
            }
        }
    }
    
    // MARK: - Update
    func updateDocument(collection: String, documentID: String, data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(collection).document(documentID).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Delete
    func deleteDocument(collection: String, documentID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(collection).document(documentID).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

extension FirestoreManager {
    // MARK: - CREATE User
    func createUserPublisher(_ user: User) -> AnyPublisher<String, Error> {
        let dto = UserDto(user)
        return Future<String, Error> { promise in
            do {
                let dict = try dto.toDictionary()
                self.createDocument(collection: "users", data: dict) { result in
                    promise(result)
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: READ User
    func readUserPublisher(documentID: String) -> AnyPublisher<User, Error> {
        Future<User, Error> { promise in
            self.readDocument(collection: "users", documentID: documentID) { result in
                switch result {
                case .success(let data):
                    do {
                        // 1) [String:Any] → JSON Data
                        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                        // 2) JSON Data → UserDto
                        let dto = try JSONDecoder().decode(UserDto.self, from: jsonData)
                        // 3) DTO → 도메인 User
                        let user = dto.toDomain(id: documentID)
                        promise(.success(user))
                    } catch {
                        promise(.failure(error))
                    }
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
 */





















/*
extension FirestoreManager {
    // MARK: - Create
    func createDocument(collection: String, data: [String: Any]) -> AnyPublisher<String, Error> {
        Future<String, Error> { promise in
            self.createDocument(collection: collection, data: data) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    

}

extension FirestoreManager {
    func createDocumentPublisher(collection: String, data: [String: Any]) -> AnyPublisher<String, Error> {
        toCombine { completion in
            self.createDocument(collection: collection, data: data, completion: completion)
        }
    }
    
    func readDocumentPublisher(collection: String, documentID: String) -> AnyPublisher<[String: Any], Error> {
        toCombine { completion in
            self.readDocument(collection: collection, documentID: documentID, completion: completion)
        }
    }
    
    func toCombine<T>(
        _ work: @escaping (@escaping (Result<T, Error>) -> Void) -> Void
    ) -> AnyPublisher<T, Error> {
        Deferred {                       // ①
            Future<T, Error> { promise in  // ②
                work { result in
                    promise(result)
                }
            }
        }
        .eraseToAnyPublisher()
    }
}


//extension Result {
//    func toCombine_saves() -> AnyPublisher<Success, Failure> {
//        Future { promise in
//            promise(self)
//        }
//        .eraseToAnyPublisher()
//    }
//}
*/
