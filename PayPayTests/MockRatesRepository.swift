//
//  MockRatesRepository.swift
//  PayPayTests
//
//  Created by Duy Quang Dao on 8/4/23.
//

import Foundation
import RxSwift
import RxCocoa
@testable import PayPay

enum MockRepositoryError: Error {
    case networkError
    case localCacheError
}

struct MockRepositoryNetworkError: RatesRepositoryType {
    var latestRatesSingle: Single<LatestRatesModel> {
        .error(MockRepositoryError.networkError)
    }

    var latestRatesFromCache: Single<LatestRatesModel> {
        .just(.mock)
    }
}

struct MockRepositoryCacheError: RatesRepositoryType {
    var latestRatesSingle: Single<LatestRatesModel> {
        .just(.mock)
    }

    var latestRatesFromCache: Single<LatestRatesModel> {
        .error(MockRepositoryError.localCacheError)
    }
}

struct MockRepositorySuccess: RatesRepositoryType {
    var latestRatesSingle: Single<LatestRatesModel> {
        .just(.mock)
    }

    var latestRatesFromCache: Single<LatestRatesModel> {
        .just(.mock)
    }
}

extension LatestRatesModel {
    static let mock = LatestRatesModel(timestamp: 0,
                                       base: "USD",
                                       rates: [
                                           "VND": 23446.66014,
                                           "JPY": 131.85310401
                                       ])
}
