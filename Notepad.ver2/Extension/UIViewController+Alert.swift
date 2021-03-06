//
//  UIViewController+Alert.swift
//  Notepad.ver2
//
//  Created by gunhyeong on 2020/07/25.
//  Copyright © 2020 geonhyeong. All rights reserved.
//
import UIKit

extension UIViewController {
    func alert(title: String = "알림" , message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAtion = UIAlertAction(title: "확인", style: .default, handler: nil)
        alert.addAction(okAtion)
        
        present(alert, animated: true, completion: nil)
    }
}
