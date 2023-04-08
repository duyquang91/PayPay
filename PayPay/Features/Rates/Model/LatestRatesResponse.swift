//
//  LatestRatesResponse.swift
//  PayPay
//
//  Created by Duy Quang Dao on 7/4/23.
//

import Foundation
import RxDataSources

struct LatestRatesModel: Codable, Equatable {
    let timestamp: TimeInterval
    let base: String
    let rates: [String: Double]
}

extension LatestRatesModel {
    var timeString: String {
        let date = Date(timeIntervalSince1970: timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        dateFormatter.locale = .current
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

extension LatestRatesModel {
    func getCurrencySymbols() -> [String] {
        return rates.map { $0.key }
    }

    func getRates(fromBase base: String) -> [String: Double] {
        guard base != self.base else { return rates }
        guard let baseValue = rates[base] else { return [:] }

        var newRates = rates
        newRates.removeValue(forKey: base)

        newRates.forEach { key, value in
            newRates[key] =  value / baseValue
        }

        newRates[self.base] = 1 / baseValue

        return newRates
    }
}
