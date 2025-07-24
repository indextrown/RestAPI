//
//  TodosTab.swift
//  RestAPI
//
//  Created by 김동현 on 7/23/25.
//

import UIKit
import SwiftUI
import Combine

class TodosTab: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        
        // 1) UIKit 탭: TodosVC
        let uikitVC = TodosVC()
        uikitVC.tabBarItem = UITabBarItem(
            title: "UIKit",
            image: UIImage(systemName: "curlybraces"),
            tag: 0)
        
        // 2) SwiftUI 탭: TodosView
        let swiftVC = UIHostingController(rootView: TodosView())
        swiftVC.tabBarItem = UITabBarItem(
            title: "SwiftUI",
            image: UIImage(systemName: "swift"),
            tag: 1)
        
        // 3) 탭 등록
        setViewControllers([uikitVC, swiftVC], animated: false)
        
    }
}

class TodosVC: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let firestoreManager = FirestoreManager()

        
        // CREATE
        firestoreManager.createDocument(collection: "users", data: ["name": "동현", "age": 25]) { result in
            switch result {
            case .success(let id):
                print("✅ 문서 생성 성공: \(id)")
            case .failure(let error):
                print("❌ 생성 실패: \(error.localizedDescription)")
            }
        }
        
        /*
        // READ
        firestoreManager.readDocument(collection: "users", documentID: "47qmXVPTlgtDUXrD664O") { result in
            switch result {
            case .success(let data):
                print("📄 읽은 데이터: \(data)")
            case .failure(let error):
                print("❌ 읽기 실패: \(error.localizedDescription)")
            }
        }
         */
        
        /*
        // Combine 기반 READ 호출
        firestoreManager
            .readDocumentPublisher(collection: "users", documentID: "47qmXVPTlgtDUXrD664O")
            .receive(on: DispatchQueue.main)   // UI 업데이트가 필요하면 메인 스레드로
            .sink { completion in
                switch completion {
                case .finished:
                    print("✅ Combine 읽기 완료")
                case .failure(let error):
                    print("❌ Combine 읽기 실패:", error.localizedDescription)
                }
            } receiveValue: { data in
                print("📄 Combine로 읽은 데이터:", data)
            }
            .store(in: &cancellables)
         */
    }
}

struct TodosView: View {
    var body: some View {
        Text("SwiftUI Todos")
    }
}
