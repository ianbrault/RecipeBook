//
//  RBTextField.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/22/23.
//

import UIKit

class RBTextField: UITextField {

    // adds internal padding
    let textPadding: UIEdgeInsets!
    let verticalPadding: CGFloat = 4
    let horizontalPadding: CGFloat = 10

    init(placeholder: String) {
        self.textPadding = UIEdgeInsets(
            top: self.verticalPadding, left: self.horizontalPadding, bottom: self.verticalPadding, right: self.horizontalPadding)
        super.init(frame: .zero)
        self.configure(placeholder: placeholder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: self.textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: self.textPadding)
    }

    private func configure(placeholder: String) {
        self.translatesAutoresizingMaskIntoConstraints = false

        self.autocapitalizationType = .none
        self.placeholder = placeholder
        self.textColor = .label
        self.tintColor = .label

        self.borderStyle = .roundedRect
    }
}
