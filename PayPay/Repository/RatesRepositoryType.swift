//
//  RatesRepositoryType.swift
//  PayPay
//
//  Created by Duy Quang Dao on 8/4/23.
//

import Foundation
import RxSwift

enum RatesRepositoryError: Error {
    case noCache
}

protocol RatesRepositoryType {
    /// Fetch data from sever & update the local cache
    var latestRatesSingle: Single<LatestRatesModel> { get }

    /// Get the latest data from cache
    var latestRatesFromCache: Single<LatestRatesModel> { get }
}
