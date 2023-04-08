//
//  CurrencyModel.swift
//  PayPay
//
//  Created by Duy Quang Dao on 7/4/23.
//

import Foundation
import RxDataSources

struct CurrencyModel: Equatable {
    let symbol: String
    let value: Double
}

extension CurrencyModel: IdentifiableType {
    var identity: String {
        symbol
    }
}
