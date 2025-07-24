//
//  ViewController.swift
//  RestAPI
//
//  Created by 김동현 on 7/20/25.
//

import UIKit
import Combine
import CombineCocoa

class ViewController: UIViewController {
    
    private var subscriptions = Set<AnyCancellable>()
    @IBOutlet weak var navToTodosApiBtn: UIButton!
    @IBOutlet weak var navToFirebaseApiBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navToTodosApiBtn
            .tapPublisher
            .sink(receiveValue: {
                print(#fileID, #function, #line, "- ")
                let vc = TodosTab()
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .store(in: &subscriptions)
        
        navToFirebaseApiBtn
            .tapPublisher
            .sink(receiveValue: {
                print(#fileID, #function, #line, "- ")
                let vc = FirebaseTab()
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .store(in: &subscriptions)
        
    }
}

