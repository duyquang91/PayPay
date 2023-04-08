//
//  RatesViewModel.swift
//  PayPay
//
//  Created by Duy Quang Dao on 7/4/23.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt

final class RatesViewModel: ViewModelType {
    struct Input {
        let refreshData: Signal<Void>
        let amount: Signal<Double>
        let base: Signal<String>
    }

    struct Output {
        let latestRatesModel: Signal<LatestRatesModel>
        let rates: Signal<[CurrencyModel]>
        let errorSignal: Signal<Error>
        let loadingSignal: Signal<Bool>
        let triggerAllowedInterval: Signal<Int>
        let triggerAllowedSignal: Driver<Bool>
    }

    private let repository: RatesRepositoryType
    private let errorRelay = PublishRelay<Error>()
    private let loadingRelay = PublishRelay<Bool>()
    private var triggerAllowedRelay = BehaviorRelay<Bool>(value: true)

    init(repository: RatesRepositoryType) {
        self.repository = repository
    }

    func transform(input: Input) -> Output {
        let interval = Signal<Int>.interval(.seconds(30 * 60))
            .do(onNext: { [weak self] _ in
                self?.triggerAllowedRelay.accept(true)
            })

        let latestRatesModel = input.refreshData
        .withUnretained(self)
        .filter { $0.0.triggerAllowedRelay.value }
        .map { $0.0 }
        .flatMapLatest { weakSelf in
            weakSelf.repository
                .latestRatesSingle
                .do(onSuccess: { _ in
                    weakSelf.triggerAllowedRelay.accept(false)
                }, onError: { error in
                    weakSelf.errorRelay.accept(error)
                    weakSelf.triggerAllowedRelay.accept(true)
                }, onSubscribe: {
                    weakSelf.loadingRelay.accept(true)
                }, onDispose: {
                    weakSelf.loadingRelay.accept(false) })
                .asSignal(onErrorSignalWith: .empty())
        }

        let cache = repository.latestRatesFromCache.asSignal(onErrorSignalWith: .empty()).delay(.milliseconds(350))
        let result = Signal.merge(latestRatesModel, cache)
            .distinctUntilChanged()

        let rates = result.map { $0.rates.map { CurrencyModel(symbol: $0.key, value: $0.value) } }
        let baseChanged = input.base
            .withLatestFrom(result) { ($0, $1) }
            .map { $0.1.getRates(fromBase: $0.0) }
            .map { $0.map { CurrencyModel(symbol: $0.key, value: $0.value) } }
        let ratesMerged = Signal.merge(rates, baseChanged)

        let ratesOutput = ratesMerged.withLatestFrom(input.amount) { ($0, $1) }
            .map { (currencies, amount) in
                currencies.map { CurrencyModel(symbol: $0.symbol, value: $0.value * amount) }
            }

        let amountRates = input.amount
            .withLatestFrom(ratesMerged) { ($0, $1) }
            .map { (amount, currencies) in
                currencies.map { CurrencyModel(symbol: $0.symbol, value: $0.value * amount) }
            }

        return .init(latestRatesModel: result,
                     rates: Signal.merge(ratesOutput, amountRates).distinctUntilChanged(),
                     errorSignal: errorRelay.asSignal(),
                     loadingSignal: loadingRelay.asSignal(),
                     triggerAllowedInterval: interval,
                     triggerAllowedSignal: input.refreshData.asDriver(onErrorJustReturn: ()).withLatestFrom(triggerAllowedRelay.asDriver()))
    }
}
