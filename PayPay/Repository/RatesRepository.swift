//
//  File.swift
//  PayPay
//
//  Created by Duy Quang Dao on 7/4/23.
//

import Foundation
import RxSwift
import RxCocoa

struct RatesRepository: RatesRepositoryType {

    private let keyLatestRatesModel = "LatestRatesModel"

    var latestRatesSingle: Single<LatestRatesModel> {
        let headers = ["accept": "application/json"]

        let request = NSMutableURLRequest(url: NSURL(string: "https://openexchangerates.org/api/latest.json?app_id=5bea6da596ae410b87cdfd8b9fe7c1cc&show_alternative=false")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        return URLSession.shared
            .rx
            .data(request: request as URLRequest)
            .decode(type: LatestRatesModel.self, decoder: JSONDecoder())
            .asSingle()
            .do(onSuccess: { response in
                print(response)
                guard let data = try? JSONEncoder().encode(response) else { return }
                UserDefaults.standard.setValue(data, forKey: keyLatestRatesModel)
                UserDefaults.standard.synchronize()
            })
                }

    var latestRatesFromCache: Single<LatestRatesModel> {
        guard let data = UserDefaults.standard.value(forKey: keyLatestRatesModel) as? Data else {
            return .error(RatesRepositoryError.noCache)
        }

        do {
            return .just(try JSONDecoder().decode(LatestRatesModel.self, from: data))
        } catch {
            return .error(error)
        }
    }
}
