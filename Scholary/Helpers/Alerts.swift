//
//  alertModels.swift
//  Scholary
//
//  Created by Andre Vasques on 10/07/25.
//

import UIKit

extension UIViewController {
    
    //MARK: - Validation Alert
    
    func validationAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmation = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(confirmation)
        self.present(alert, animated: true, completion: nil)
    }
    
    func validationWithDismiss(title: String, message: String, onConfirm: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmation = UIAlertAction(title: "OK", style: .default) { _ in
            onConfirm?()
        }
        alert.addAction(confirmation)
        self.present(alert, animated: true, completion: nil)
    }
    
    func confirmationAlert(title: String, message: String, onConfirm: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmation = UIAlertAction(title: "Continuar", style: .default) { _ in
            onConfirm?()
        }
        let cancel = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        alert.addAction(confirmation)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
}
