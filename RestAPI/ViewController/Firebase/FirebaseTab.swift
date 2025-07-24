//
//  FirebaseTab.swift
//  RestAPI
//
//  Created by 김동현 on 7/25/25.
//

import UIKit
import SwiftUI
import Combine

class FirebaseTab: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        
        // 1) UIKit 탭: TodosVC
        let uikitVC = FirebaseVC()
        uikitVC.tabBarItem = UITabBarItem(
            title: "UIKit",
            image: UIImage(systemName: "curlybraces"),
            tag: 0)
        
        // 2) SwiftUI 탭: TodosView
        let swiftVC = UIHostingController(rootView: FirebaseView())
        swiftVC.tabBarItem = UITabBarItem(
            title: "SwiftUI",
            image: UIImage(systemName: "swift"),
            tag: 1)
        
        // 3) 탭 등록
        setViewControllers([uikitVC, swiftVC], animated: false)
    }
}

class FirebaseVC: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    private let collection = "users"
    private let sampleID = "SNRC1736tVKlqLLlckIt"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
    }
}

// MARK: - 기본 CRUD 호출
extension FirebaseVC {
    
    private func basicCreateExample() {
        let data: [String: Any] = ["name": "동현", "age": 26]
        FirestoreManager.shared.createDocument(
            collection: collection,
            data: data
        ) { result in
            switch result {
            case .success(let documentID):
                print("✅ 기본 Create 성공, 문서 ID: \(documentID)")
            case .failure(let error):
                print("❌ 기본 Create 실패:", error)
            }
        }
    }
    
    private func basicReadExample() {
        FirestoreManager.shared.readDocument(
            collection: collection,
            documentID: sampleID
        ) { result in
            switch result {
            case .success(let data):
                print("📖 기본 Read 성공:", data)
            case .failure(let error):
                print("❌ 기본 Read 실패:", error)
            }
        }
    }
    
    private func basicUpdateExample() {
        let updatedData: [String: Any] = ["age": 27]
        FirestoreManager.shared.updateDocument(
            collection: collection,
            documentID: sampleID,
            data: updatedData
        ) { result in
            switch result {
            case .success:
                print("✏️ 기본 Update 성공")
            case .failure(let error):
                print("❌ 기본 Update 실패:", error)
            }
        }
    }
    
    private func basicDeleteExample() {
        FirestoreManager.shared.deleteDocument(
            collection: collection,
            documentID: sampleID
        ) { result in
            switch result {
            case .success:
                print("🗑️ 기본 Delete 성공")
            case .failure(let error):
                print("❌ 기본 Delete 실패:", error)
            }
        }
    }
}

// MARK: - 제네릭 CRUD 호출(Entity로 받을 수 있음)
extension FirebaseVC {
    
    private func createExample() {
        // 1) 도메인 모델 생성
        let user   = User(id: nil, name: "동현", age: 26)
        // 2) DTO 변환
        let dto    = UserDto(user)
        
        FirestoreManager.shared.createGenericDocument(
            collection: collection,
            object: dto
        ) { result in
            switch result {
            case .success(let documentID):
                print("✅ Create 성공, 문서 ID:", documentID)
            case .failure(let error):
                print("❌ Create 실패:", error)
            }
        }
    }
    
    private func readSingleExample() {
        FirestoreManager.shared.readGenericDocument(
            collection: collection,
            documentID: sampleID,
            as: UserDto.self         // DTO 타입으로 요청
        ) { result in
            switch result {
            case .success(let dto):
                // DTO → 도메인 모델
                let user = dto.toDomain(id: self.sampleID)
                print("📖 Read Single 성공:", user)
                
            case .failure(let error):
                print("❌ Read Single 실패:", error)
            }
        }
    }
    
    private func readCollectionExample() {
        FirestoreManager.shared.readGenericCollection(
            collection: collection,
            as: UserDto.self
        ) { result in
            switch result {
            case .success(let dtos):
                // DTO 배열 → User 배열
                let users = dtos.map { $0.toDomain(id: nil) }
                print("📚 Read Collection 성공, 총 \(users.count)개:", users)
                
            case .failure(let error):
                print("❌ Read Collection 실패:", error)
            }
        }
    }
    
    private func updateExample() {
        // 1) 기존 User를 수정
        var user = User(id: sampleID, name: "동현", age: 26)
        user.age += 1
        
        // 2) DTO로 변환
        let dto  = UserDto(user)
        
        FirestoreManager.shared.updateGenericDocument(
            collection: collection,
            documentID: sampleID,
            with: dto
        ) { result in
            switch result {
            case .success:
                print("✏️ Update 성공")
            case .failure(let error):
                print("❌ Update 실패:", error)
            }
        }
    }
    
    private func deleteExample() {
        FirestoreManager.shared.deleteGenericDocument(
            collection: collection,
            documentID: sampleID
        ) { result in
            switch result {
            case .success:
                print("🗑 Delete 성공")
            case .failure(let error):
                print("❌ Delete 실패:", error)
            }
        }
    }
}

// MARK: - Combine 호출 예시
extension FirebaseVC {
    /// Create 문서 생성
    private func createWithCombine() {
        let dto = UserDto(User(id: nil, name: "동현", age: 26))
        
        FirestoreManager.shared
            .createGenericPublisher(collection: collection, object: dto)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ Combine Create 실패:", error)
                }
            } receiveValue: { documentID in
                print("✅ Combine Create 성공, ID:", documentID)
            }
            .store(in: &cancellables)
    }
    
    /// Read Single 단일 문서 읽기
    private func readSingleWithCombine() {
        FirestoreManager.shared
            .readGenericPublisher(collection: collection, documentID: sampleID, as: UserDto.self)
            .map { $0.toDomain(id: self.sampleID) }
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ Combine Read Single 실패:", error)
                }
            } receiveValue: { user in
                print("✅ Combine Read Single 성공:", user)
            }
            .store(in: &cancellables)
    }
    
    /// Read Collection 컬렉션 전체 읽기
    private func readAllWithCombine() {
        FirestoreManager.shared
            .readGenericCollectionPublisher(collection: collection, as: UserDto.self)
            .map { dtos in dtos.map { $0.toDomain(id: nil) } }
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ Combine Read Collection 실패:", error)
                }
            } receiveValue: { users in
                print("✅ Combine Read Collection 성공, 총 \(users.count)개:", users)
            }
            .store(in: &cancellables)
    }
    
    /// Update 문서 업데이트
    private func updateWithCombine() {
        var user = User(id: sampleID, name: "동현", age: 26)
        user.age += 1
        let dto = UserDto(user)
        
        FirestoreManager.shared
            .updateGenericPublisher(collection: collection, documentID: sampleID, with: dto)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ Combine Update 실패:", error)
                }
            } receiveValue: {
                print("✅ Combine Update 성공")
            }
            .store(in: &cancellables)
    }
    
    /// Delete 문서 삭제
    private func deleteWithCombine() {
        FirestoreManager.shared
            .deleteGenericPublisher(collection: collection, documentID: sampleID)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ Combine Delete 실패:", error)
                }
            } receiveValue: {
                print("✅ Combine Delete 성공")
            }
            .store(in: &cancellables)
    }
}

struct FirebaseView: View {
    var body: some View {
        Text("SwiftUI Firebase")
    }
}
