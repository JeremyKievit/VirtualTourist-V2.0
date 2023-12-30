//
//  Alerts.swift
//  VirtualTourist
//
//  Created by admin on 12/31/20.
//  Copyright © 2020 Com.JeremyKievit. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    //MARK: Error alert
    func errorAlert(text : String, message : String, action: String) {
        let alert = UIAlertController(title: text, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: action, style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
