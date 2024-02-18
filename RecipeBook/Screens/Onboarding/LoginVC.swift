//
//  LoginVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/16/23.
//

import UIKit

class LoginVC: UIViewController {

    let backButton = RBPlainButton(title: "Back", image: SFSymbols.arrowBack)
    let titleLabel = RBTitleLabel(fontSize: 30)
    let emailField = RBIconTextField(placeholder: "Email", image: SFSymbols.email!)
    let passwordField = RBIconTextField(placeholder: "Password", image: SFSymbols.password!)
    let submitButton = RBButton(title: "Login")

    let spacing: CGFloat = 16
    let topPadding: CGFloat = 16
    let bottomPadding: CGFloat = 64

    let textFieldHeight: CGFloat = 40
    let textFieldPadding: CGFloat = 36

    let buttonHeight: CGFloat = 58
    let buttonPadding: CGFloat = 64

    weak var delegate: OnboardingVCDelegate?
    weak var sceneDelegate: RBWindowSceneDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViewController()
        self.configureBackButton()
        self.configureTitleLabel()
        self.configureTextFields()
        self.configureSubmitButton()
        self.createDismissKeyboardTapGesture()
        self.createSwipeGesture()
    }

    private func configureViewController() {
        self.view.backgroundColor = .systemBackground
    }

    private func configureBackButton() {
        self.view.addSubview(self.backButton)

        self.backButton.addTarget(self, action: #selector(self.backButtonPressed), for: .touchUpInside)

        NSLayoutConstraint.activate([
            self.backButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: self.topPadding),
            self.backButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.backButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    private func configureTitleLabel() {
        self.view.addSubview(self.titleLabel)

        self.titleLabel.text = "Log In"

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.backButton.bottomAnchor, constant: self.spacing),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.textFieldPadding),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.textFieldPadding),
            self.titleLabel.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private func configureTextFields() {
        self.view.addSubview(self.emailField)
        self.view.addSubview(self.passwordField)

        self.emailField.textField.textContentType = .username
        self.emailField.textField.keyboardType = .emailAddress

        self.passwordField.textField.textContentType = .password
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

    private func createSwipeGesture() {
        let swipe = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.backButtonPressed))
        swipe.edges = .left
        self.view.addGestureRecognizer(swipe)
    }

    @objc func backButtonPressed() {
        self.delegate?.didChangePage(page: .welcome, direction: .reverse)
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

        let email = self.emailField.text!
        let password = self.passwordField.text!
        // hash the password before sending to the server
        var hashedPassword: String
        switch hashPassword(password) {
        case .success(let hash):
            hashedPassword = hash.base64EncodedString()
        case .failure(let error):
            self.presentErrorAlert(error)
            return
        }

        self.showLoadingView()
        API.login(email: email, password: hashedPassword) { [weak self] (result) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let userInfo):
                    // store the user info to the app state and transition to the normal flow
                    if let error = State.manager.addUserInfo(info: userInfo) {
                        self.presentErrorAlert(error)
                    } else {
                        self.sceneDelegate?.sceneDidAddUser()
                    }
                case .failure(let error):
                    self.presentErrorAlert(error)
                }
            }
            self.dismissLoadingView()
        }
    }
}
