//
//  PayPayTests.swift
//  PayPayTests
//
//  Created by Duy Quang Dao on 5/4/23.
//

import XCTest
@testable import PayPay

final class RatesModelTests: XCTestCase {

    func testRatesConvert() {
        let rateModel = LatestRatesModel.mock

        XCTAssertTrue(rateModel.getCurrencySymbols().contains("VND") && rateModel.getCurrencySymbols().contains("JPY"))
        XCTAssertEqual(rateModel.rates, rateModel.getRates(fromBase: "USD"))
        XCTAssertEqual([:], rateModel.getRates(fromBase: ""))
        XCTAssertEqual([:], rateModel.getRates(fromBase: "Test"))

        let newVND = rateModel.getRates(fromBase: "VND")
        XCTAssertEqual(newVND["USD"], 1 / 23446.66014)
        XCTAssertEqual(newVND["JPY"], 131.85310401 / 23446.66014)
        XCTAssertNil(newVND["Test"])

        let newJPY = rateModel.getRates(fromBase: "JPY")
        XCTAssertEqual(newJPY["USD"], 1 / 131.85310401)
        XCTAssertEqual(newJPY["VND"], 23446.66014 / 131.85310401)
        XCTAssertNil(newJPY["Test"])
    }
}
