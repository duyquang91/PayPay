//
//  ViewModelTests.swift
//  PayPayTests
//
//  Created by Duy Quang Dao on 8/4/23.
//

import Foundation
import XCTest
import RxSwift
import RxCocoa
import RxBlocking
@testable import PayPay

final class RatesViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Removed cache
        UserDefaults.standard.removeObject(forKey: "LatestRatesModel")
    }

    func testViewModelWithNetworkError() {
        let vm = RatesViewModel(repository: MockRepositoryNetworkError())
        let errorRelay = BehaviorRelay<Error?>(value: nil)
        let output = vm.transform(input: .init(refreshData: .just(()),
                                               amount: .empty(),
                                               base: .empty()))

        output.errorSignal.emit(to: errorRelay)
        output.latestRatesModel.emit()

        // Should throw error
        XCTAssertEqual(try? errorRelay.asDriver().unwrap().toBlocking().first() as? MockRepositoryError, MockRepositoryError.networkError)
    }

    func testViewModelWithNetworkErrorWithLocalCache() {
        let vm = RatesViewModel(repository: MockRepositoryNetworkError())
        let errorRelay = BehaviorRelay<Error?>(value: nil)
        let output = vm.transform(input: .init(refreshData: .just(()),
                                               amount: .empty(),
                                               base: .empty()))
        output.errorSignal.emit(to: errorRelay)

        // Set local cache
        UserDefaults.standard.set(try! JSONEncoder().encode(LatestRatesModel.mock), forKey: "LatestRatesModel")

        // Should get the data from local cache
        XCTAssertEqual(try? output.latestRatesModel.toBlocking().first(), .mock)

        // Should throw error from network
        XCTAssertEqual(try? errorRelay.asDriver().unwrap().toBlocking().first() as? MockRepositoryError, MockRepositoryError.networkError)
    }

    func testViewModelWithLocalCacheError() {
        let vm = RatesViewModel(repository: MockRepositoryNetworkError())
        let errorRelay = BehaviorRelay<Error?>(value: nil)
        let output = vm.transform(input: .init(refreshData: .just(()),
                                               amount: .empty(),
                                               base: .empty()))

        // Should get the response from sever when cache is empty
        XCTAssertEqual(try? output.latestRatesModel.toBlocking().first(), .mock)
    }

    func testViewModelWithAmount() {
        let vm = RatesViewModel(repository: MockRepositorySuccess())
        let output = vm.transform(input: .init(refreshData: .just(()),
                                               amount: .just(2.0),
                                               base: .empty()))

        // First, display the 1x by default
        XCTAssertEqual(try! output.latestRatesModel.toBlocking().first().map { Set($0.rates.map { $0.value }) }, [131.85310401, 23446.66014])

        // Rates must be x2 by amount
        XCTAssertEqual(try! output.rates.toBlocking().first().map { Set($0.map { $0.value }) }, [263.70620802, 46893.32028])
    }

    func testViewModelWithBaseChage() {
        let vm = RatesViewModel(repository: MockRepositorySuccess())
        let baseRelay = PublishRelay<String>()
        let refreshDataRelay = PublishRelay<Void>()
        let amountRelay = PublishRelay<Double>()
        let currencyRelay = BehaviorRelay<[CurrencyModel]?>(value: nil)
        let output = vm.transform(input: .init(refreshData: refreshDataRelay.asSignal(),
                                               amount: amountRelay.asSignal(),
                                               base: baseRelay.asSignal()))

        output.rates.emit(to: currencyRelay)
        output.latestRatesModel.emit()

        refreshDataRelay.accept(())
        amountRelay.accept(1.0)
        try! currencyRelay.asDriver().unwrap().toBlocking().first()

        baseRelay.accept("JPY")
        // Should add new "USD"
        XCTAssertTrue(try! currencyRelay.asDriver().unwrap().toBlocking().first()!.map { $0.symbol }.contains("USD"))
        // Should remove "JPY"
        XCTAssertFalse(try! currencyRelay.asDriver().unwrap().toBlocking().first()!.map { $0.symbol }.contains("JPY"))

    }
}
