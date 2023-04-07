//
//  BaseViewController.swift
//  PayPay
//
//  Created by Duy Quang Dao on 7/4/23.
//

import Foundation
import RxSwift

/// An abstraction of  *View* component in MVVM design
///
/// All *View* components such as UIView, UIViewController, ... should conform this
/// *View* is responsible to handle the disposeBag therefore manages its *ViewModel* life cycle
public protocol ViewType {
    associatedtype ViewModel: ViewModelType
    /// Associated *ViewModel* belongs to this *View*
    var viewModel: ViewModel { get }
    /// All subscription will be handled in *View* instead of *ViewModel*
    var disposeBag: DisposeBag { get }
}
