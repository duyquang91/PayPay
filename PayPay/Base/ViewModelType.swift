//
//  ViewModelType.swift
//  PayPay
//
//  Created by Duy Quang Dao on 7/4/23.
//

import Foundation

/// An abstraction of *ViewModel* component in MVVM design
///
/// *ViewModel* should be stateless & responsible to process input streams from *View* then update back to *View*
/// DO NOT store any subscription here, it should be responsible of *View*
public protocol ViewModelType {
    /// Input streams from *View*
    associatedtype Input
    /// Output would reflect to *View*
    associatedtype Output

    func transform(input: Input) -> Output
}
