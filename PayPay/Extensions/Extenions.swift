//
//  UIViewController+Extensions.swift
//  PayPay
//
//  Created by Duy Quang Dao on 7/4/23.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alrt = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alrt.addAction(.init(title: "Dismiss", style: .cancel))

        present(alrt, animated: true)
    }
}

extension Double {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 5
        formatter.numberStyle = .decimal
        return formatter.string(from: self as NSNumber) ?? "N/A"
    }
}
