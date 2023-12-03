//
//  RecipeFormCell.swift
//  RecipeBook
//
//  Created by Ian Brault on 3/26/23.
//

import UIKit

protocol RecipeFormCellDelegate: AnyObject {
    func textFieldDidBeginEditing(_: UUID)
    func textFieldDidChange(_: UUID, text: String?)
    func ingredientsButtonPressed()
    func instructionsButtonPressed()
}

class RecipeFormCell: UITableViewCell {
    static let reuseID = "RecipeFormCell"

    enum ContentType {
        case input
        case actionButton
    }

    struct Content {
        var type: ContentType
        var uuid: UUID
        var text: String? = nil

        static func createInput() -> Content {
            return Content(type: .input, uuid: UUID(), text: "")
        }

        static func createInput(text: String) -> Content {
            return Content(type: .input, uuid: UUID(), text: text)

        }

        static func createInput(uuid: UUID, text: String) -> Content {
            return Content(type: .input, uuid: uuid, text: text)
        }

        static func createButton() -> Content {
            return Content(type: .actionButton, uuid: UUID())
        }
    }

    var section: RecipeFormVC.Section?
    var uuid: UUID?
    var textField: RBCellTextField?
    var actionButton: RBPlainButton?

    weak var delegate: RecipeFormCellDelegate?

    override func prepareForReuse() {
        super.prepareForReuse()

        self.textField?.removeFromSuperview()
        self.textField = nil

        self.actionButton?.removeFromSuperview()
        self.actionButton = nil
    }

    func setInput(section: RecipeFormVC.Section, uuid: UUID, text: String) {
        self.section = section
        self.uuid = uuid

        self.textField = RBCellTextField(placeholder: section.textFieldPlaceholder, horizontalPadding: 20)
        self.textField?.delegate = self
        self.textField?.text = text
        if section == .title {
            self.textField?.autocapitalizationType = .words
        }
        self.textField?.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        self.addSubview(self.textField!)

        NSLayoutConstraint.activate([
            self.textField!.topAnchor.constraint(equalTo: self.topAnchor, constant: 1),
            self.textField!.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1),
            self.textField!.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.textField!.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
    }

    func setActionButton(section: RecipeFormVC.Section, uuid: UUID) {
        self.section = section
        self.uuid = uuid

        self.actionButton = RBPlainButton(title: section.actionButtonText!, systemImageName: "plus.circle")
        self.actionButton!.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        self.addSubview(self.actionButton!)

        NSLayoutConstraint.activate([
            self.actionButton!.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
            self.actionButton!.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
            self.actionButton!.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
        ])
    }

    func set(section: RecipeFormVC.Section, content: Content) {
        self.contentView.isUserInteractionEnabled = false

        switch content.type {
        case .input:
            self.setInput(section: section, uuid: content.uuid, text: content.text!)
        case .actionButton:
            self.setActionButton(section: section, uuid: content.uuid)
        }
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        self.delegate?.textFieldDidChange(self.uuid!, text: textField.text)
    }

    @objc func buttonPressed() {
        if let section = self.section {
            switch section {
            case .title:
                break
            case .ingredients:
                self.delegate?.ingredientsButtonPressed()
            case .instructions:
                self.delegate?.instructionsButtonPressed()
            }
        }
    }
}

extension RecipeFormCell: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidBeginEditing(self.uuid!)
    }
}
