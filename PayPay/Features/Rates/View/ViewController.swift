//
//  ViewController.swift
//  PayPay
//
//  Created by Duy Quang Dao on 5/4/23.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt
import RxDataSources
import MBProgressHUD

final class RatesViewController: UIViewController, ViewType {
    @IBOutlet private var lblStatus: UILabel!
    @IBOutlet private var btnRefresh: UIButton!
    @IBOutlet private var btnBase: UIButton!
    @IBOutlet private var tableView: UITableView!

    typealias ViewModel = RatesViewModel

    let viewModel = ViewModel(repository: RatesRepository())
    let disposeBag = DisposeBag()
    private let viewDidAppearRelay = PublishRelay<Void>()
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, CurrencyModel>> { _, tableView, indexPath, item in
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier") else {
            return UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
        }

        cell.textLabel?.text = item.symbol
        cell.detailTextLabel?.text = item.value.currencyString

        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        binding()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearRelay.accept(())
    }

    private func binding() {
        let refreshTrigger = Signal.merge(btnRefresh.rx.tap.asSignal(), viewDidAppearRelay.asSignal())
        let output = viewModel.transform(input: .init(refreshData: refreshTrigger))

        output.errorSignal
            .emit(onNext: { [weak self] error in
                self?.showAlert(title: "Error", message: error.localizedDescription)
            })
            .disposed(by: disposeBag)

        output.loadingSignal
            .withUnretained(self)
            .emit(onNext: { (weakSelf, isLoading) in
                if isLoading {
                    MBProgressHUD.showAdded(to: weakSelf.view, animated: true)
                } else {
                    MBProgressHUD.hide(for: weakSelf.view, animated: true)
                }
            })
            .disposed(by: disposeBag)

        output.latestRatesModel
            .map { "Last updated: \($0.timeString)" }
            .emit(to: lblStatus.rx.text)
            .disposed(by: disposeBag)

        output.latestRatesModel
            .map { "▼ \($0.base)" }
            .emit(to: btnBase.rx.title(for: .normal))
            .disposed(by: disposeBag)

        output.latestRatesModel
            .map { $0.rates.map { CurrencyModel(symbol: $0.key, value: $0.value) } }
            .map { [SectionModel<String, CurrencyModel>(model: "", items: $0)] }
            .asObservable()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
}

