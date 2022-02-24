//
//  UIViewController+Extension.swift
//  VirtualTourist
//
//  Created by 嶋田省吾 on 2022/02/25.
//

import UIKit

extension UIViewController {
    
    func showAlert(title: String, message: String){
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    
}
