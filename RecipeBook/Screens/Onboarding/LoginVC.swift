//
//  LoginVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/16/23.
//

import UIKit

class LoginVC: UIViewController {

    let titleLabel = RBTitleLabel(fontSize: 28)
    let emailField = RBIconTextField(placeholder: "Email", image: SFSymbols.email!)
    let passwordField = RBIconTextField(placeholder: "Password", image: SFSymbols.password!)
    let submitButton = RBButton(title: "Login")

    let spacing: CGFloat = 16
    let topPadding: CGFloat = 32
    let bottomPadding: CGFloat = 64

    let textFieldHeight: CGFloat = 44
    let textFieldPadding: CGFloat = 36

    let buttonHeight: CGFloat = 58
    let buttonPadding: CGFloat = 64

    weak var delegate: OnboardingVCDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureTitleLabel()
        self.configureTextFields()
        self.configureSubmitButton()
        self.createDismissKeyboardTapGesture()
    }

    private func configureViewController() {
        self.view.backgroundColor = .systemBackground
    }

    private func configureTitleLabel() {
        self.view.addSubview(self.titleLabel)

        self.titleLabel.text = "Log In"

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: self.topPadding),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.textFieldPadding),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.textFieldPadding),
            self.titleLabel.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private func configureTextFields() {
        self.view.addSubview(self.emailField)
        self.view.addSubview(self.passwordField)

        self.passwordField.textField.isSecureTextEntry = true

        NSLayoutConstraint.activate([
            self.emailField.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: self.spacing * 1.5),
            self.emailField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.textFieldPadding),
            self.emailField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.textFieldPadding),
            self.emailField.heightAnchor.constraint(equalToConstant: self.textFieldHeight),

            self.passwordField.topAnchor.constraint(equalTo: self.emailField.bottomAnchor, constant: self.spacing),
            self.passwordField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.textFieldPadding),
            self.passwordField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.textFieldPadding),
            self.passwordField.heightAnchor.constraint(equalToConstant: self.textFieldHeight),
        ])
    }

    private func configureSubmitButton() {
        self.view.addSubview(self.submitButton)

        self.submitButton.addTarget(self, action: #selector(self.submitButtonPressed), for: .touchUpInside)

        NSLayoutConstraint.activate([
            self.submitButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -self.bottomPadding),
            self.submitButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.buttonPadding),
            self.submitButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.buttonPadding),
            self.submitButton.heightAnchor.constraint(equalToConstant: self.buttonHeight),
        ])
    }

    private func createDismissKeyboardTapGesture() {
        // dismiss the keyboard when the view is tapped
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        self.view.addGestureRecognizer(tap)
    }

    @objc func submitButtonPressed() {
        // check if any of the fields are empty
        var emptyField = false
        if self.emailField.text?.isEmpty ?? true {
            self.emailField.setTint(color: .systemRed, animated: false)
            emptyField = true
        }
        if self.passwordField.text?.isEmpty ?? true {
            self.passwordField.setTint(color: .systemRed, animated: false)
            emptyField = true
        }
        if emptyField {
            return
        }

        // TODO: incomplete
    }
}
