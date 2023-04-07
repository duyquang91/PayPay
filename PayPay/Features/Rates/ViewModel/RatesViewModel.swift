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

class RatesViewModel: ViewModelType {
    struct Input {
        let refreshData: Signal<Void>
    }

    struct Output {
        let latestRatesModel: Signal<LatestRatesModel>
        let errorSignal: Signal<Error>
        let loadingSignal: Signal<Bool>
    }

    private let repository: RatesRepository
    private let errorRelay = PublishRelay<Error>()
    private let loadingRelay = PublishRelay<Bool>()

    init(repository: RatesRepository) {
        self.repository = repository
    }

    func transform(input: Input) -> Output {
        let latestRatesModel = input.refreshData
            .withUnretained(self)
            .map { $0.0 }
            .flatMapLatest { weakSelf in
                weakSelf.repository
                        .latestRatesSingle
                        .do(onError: { error in
                                weakSelf.errorRelay.accept(error)
                            }, onSubscribe: {
                                weakSelf.loadingRelay.accept(true)
                            }, onDispose: {
                                weakSelf.loadingRelay.accept(false)
                        })
                        .asSignal(onErrorSignalWith: .empty())
            }

        let cache = repository.latestRatesFromCache
                              .asSignal(onErrorSignalWith: .empty())

        let result = Signal.merge(latestRatesModel, cache)

        return .init(latestRatesModel: result.distinctUntilChanged(),
                     errorSignal: errorRelay.asSignal(),
                     loadingSignal: loadingRelay.asSignal())
    }
}
