//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

class CreateFolderViewController: UIViewController {
    var handlers: FolderCreationHandlers?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Create Folder"

        createSubviews()

        keyboardInsetAdjuster = KeyboardInsetAdjuster(scrollView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Addresses a bug where the keyboard is brought up with the view
        // controller, which is not laid out yet, and so the inset adjuster
        // sees the wrong safe area.
        UIView.performWithoutAnimation {
            view.layoutSubviews()
        }
        nameField.becomeFirstResponder()
    }

    // MARK: - Views

    private func createSubviews() {
        view.addSubview(scrollView)
        view.constrain(scrollView, insets: .zero)

        scrollContentView.addSubview(nameField)
        scrollContentView.constrain(nameField, top: 8, leading: 8, trailing: 8)

        scrollContentView.addSubview(warningLabel)
        scrollContentView.constrain(warningLabel, leading: 8, trailing: 8)
        NSLayoutConstraint.activate([
            warningLabel.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 20)
        ])
    }

    private(set) lazy var nameField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Folder name"
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .done
        field.enablesReturnKeyAutomatically = true

        field.delegate = self
        field.addTarget(self, action: #selector(textFieldValueDidChange), for: .editingChanged)

        return field
    }()

    let warningLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(scrollContentView)
        // Set the content view up to dictate the scrollview's content size
        scroll.constrain(scrollContentView, insets: .zero)
        // Set the content size to the width of the scrollview
        scroll.widthAnchor.constraint(equalTo: scrollContentView.widthAnchor).isActive = true

        return scroll
    }()

    let scrollContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Listens to keyboard notifications and adjusts the scrollview content inset
    private var keyboardInsetAdjuster: KeyboardInsetAdjuster?
}

// MARK: - Handlers

private extension CreateFolderViewController {
    func validate(name: String) -> FolderCreationHandlers.LocalNameValidationResult {
        handlers?.validateName(name) ?? .valid(name: name)
    }

    func validName(_ name: String) -> String? {
        if case let .valid(validName) = validate(name: name) {
            return validName
        }
        return nil
    }

    func createFolder(name _: String) -> Bool {
        return true
    }
}

// MARK: - UITextFieldDelegate

extension CreateFolderViewController: UITextFieldDelegate {
    @objc
    private func textFieldValueDidChange(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else {
            warningLabel.text = ""
            return
        }
        switch validate(name: text) {
        case .valid:
            warningLabel.text = ""
        case let .warning(reason):
            warningLabel.text = reason
            warningLabel.textColor = UIColor { traits in
                (traits.userInterfaceStyle == .dark) ? #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1) : #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)
            }
        case let .invalid(reason):
            warningLabel.text = reason
            warningLabel.textColor = UIColor { traits in
                (traits.userInterfaceStyle == .dark) ? #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1) : #colorLiteral(red: 0.3176470697, green: 0.07450980693, blue: 0.02745098062, alpha: 1)
            }
        }
    }

    @objc
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let name = validName(textField.text ?? "") else {
            return false
        }
        return createFolder(name: name)
    }
}

// MARK: - Convenience

extension CreateFolderViewController {
    static func viewControllerForModalPresentation(
        suggestedName: String? = nil,
        handlers: FolderCreationHandlers
    ) -> UINavigationController {
        let viewController = CreateFolderViewController(nibName: nil, bundle: nil)
        viewController.nameField.text = suggestedName
        viewController.handlers = handlers
        return UINavigationController(rootViewController: viewController)
    }
}
