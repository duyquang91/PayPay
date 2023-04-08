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
    @IBOutlet private var txtFieldAmount: UITextField!
    @IBOutlet private var pickerView: UIPickerView!
    @IBOutlet private var lblStatus: UILabel!
    @IBOutlet private var btnRefresh: UIButton!
    @IBOutlet private var btnBase: UIButton!
    @IBOutlet private var tableView: UITableView!
    
    typealias ViewModel = RatesViewModel
    
    let viewModel = ViewModel(repository: RatesRepository())
    let disposeBag = DisposeBag()
    private let viewDidAppearRelay = PublishRelay<Void>()
    private let baseRelay = PublishRelay<String>()
    private lazy var dataSource = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, CurrencyModel>>(configureCell: { _, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier") ?? UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
        cell.textLabel?.text = item.symbol
        cell.detailTextLabel?.text = item.value.currencyString
        return cell
    }, titleForHeaderInSection: { dataSource, section in
        dataSource.sectionModels[section].identity
    }, sectionIndexTitles: { dataSource in
        dataSource.sectionModels.map { $0.identity }
    })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtFieldAmount.delegate = self
        
        binding()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearRelay.accept(())
    }
    
    private func binding() {
        
        let refreshTrigger = Signal.merge(btnRefresh.rx.tap.asSignal(), viewDidAppearRelay.asObservable().take(1).asSignal(onErrorJustReturn: ()))
        let amountTrigger = txtFieldAmount.rx
            .text
            .unwrap()
            .map { Double($0) ?? 1 }
            .asSignal(onErrorJustReturn: 1)
            .startWith(1)
        
        let output = viewModel.transform(input: .init(refreshData: refreshTrigger,
                                                      amount: amountTrigger,
                                                      base: baseRelay.asSignal()))
        
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
            .map { $0.base }
            .emit(to: btnBase.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        output.rates
            .map { Dictionary(grouping: $0, by: { String($0.symbol.first!) }) }
            .map { $0.map { AnimatableSectionModel<String, CurrencyModel>(model: $0.key, items: $0.value) }.sorted(by: { $0.identity < $1.identity }) }
            .asObservable()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        output.rates
            .map { $0.sorted(by: { $0.symbol < $1.symbol }) }
            .map { UIMenu(children: $0.map { UIAction(title: $0.symbol, handler: { [weak self] acttion in self?.baseRelay.accept(acttion.title) }) }) }
            .emit(to: btnBase.rx.menu)
            .disposed(by: disposeBag)
        
        output.triggerAllowedInterval
            .emit()
            .disposed(by: disposeBag)

        output.triggerAllowedSignal
            .filter { !$0 }
            .drive(with: self) { weakSelf, _ in
                weakSelf.showAlert(title: "Tip", message: "The rates aren't chaged frequently. Recommend to refresh after 30 minutes.")
            }
            .disposed(by: disposeBag)
        
        baseRelay.asSignal()
            .emit(to: btnBase.rx.title(for: .normal))
            .disposed(by: disposeBag)
    }
}

extension RatesViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.text != "" || string != "" {
            let res = (textField.text ?? "") + string
            return Double(res) != nil
        }
        return true
    }}
