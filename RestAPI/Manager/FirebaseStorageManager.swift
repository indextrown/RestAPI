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
    
    // READ User
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
