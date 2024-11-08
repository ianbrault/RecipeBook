//
//  WelcomeVC.swift
//  RecipeBook
//
//  Created by Ian Brault on 11/16/23.
//

import UIKit

//
// Initial onboarding screen
// Prompts the user to log in or create an account
//
class WelcomeVC: UIViewController {

    private let imageView = UIImageView()
    private let titleLabel = TitleLabel(textAlignment: .center)
    private let messageLabel = BodyLabel(textAlignment: .center)
    private let registerButton = Button(title: "Create a New Account", style: .primary)
    private let loginButton = Button(title: "Login to your Account", style: .secondary)

    private let imageSize: CGFloat = 160
    private let buttonHeight: CGFloat = 54
    private let insets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.configureLabels()
        self.configureImageView()
        self.configureButtons()
    }

    private func configureLabels() {
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.messageLabel)

        self.titleLabel.text = "Welcome!"
        self.titleLabel.numberOfLines = 0

        self.messageLabel.text = "Create a new account to begin storing your recipes or log in to access your collection"
        self.messageLabel.textColor = .secondaryLabel
        self.messageLabel.numberOfLines = 0

        self.titleLabel.pinToSides(of: self.view)
        self.titleLabel.bottomAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -20).isActive = true

        self.messageLabel.pinToSides(of: self.view, insets: self.insets)
        self.messageLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 8).isActive = true
    }

    private func configureImageView() {
        self.view.addSubview(self.imageView)

        self.imageView.image = UIImage(named: "Logo")
        self.imageView.translatesAutoresizingMaskIntoConstraints = false

        self.imageView.bottomAnchor.constraint(equalTo: self.titleLabel.topAnchor, constant: -16).isActive = true
        self.imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.imageView.widthAnchor.constraint(equalToConstant: self.imageSize).isActive = true
        self.imageView.heightAnchor.constraint(equalToConstant: self.imageSize).isActive = true
    }

    private func configureButtons() {
        self.view.addSubview(self.registerButton)
        self.view.addSubview(self.loginButton)

        self.registerButton.addTarget(self, action: #selector(self.registerButtonPressed), for: .touchUpInside)
        self.loginButton.addTarget(self, action: #selector(self.loginButtonPressed), for: .touchUpInside)

        self.loginButton.pinToSides(of: self.view, insets: self.insets)
        self.loginButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -self.insets.bottom).isActive = true
        self.loginButton.heightAnchor.constraint(equalToConstant: self.buttonHeight).isActive = true

        self.registerButton.pinToSides(of: self.view, insets: self.insets)
        self.registerButton.bottomAnchor.constraint(equalTo: self.loginButton.topAnchor, constant: -16).isActive = true
        self.registerButton.heightAnchor.constraint(equalToConstant: self.buttonHeight).isActive = true
    }

    @objc func registerButtonPressed() {
        self.navigationController?.pushViewController(OnboardingFormVC(.register), animated: true)
    }

    @objc func loginButtonPressed() {
        self.navigationController?.pushViewController(OnboardingFormVC(.login), animated: true)
    }
}
