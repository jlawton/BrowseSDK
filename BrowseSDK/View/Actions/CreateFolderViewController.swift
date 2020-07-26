//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

class CreateFolderViewController: UIViewController, NeedsCreateFolderViewModel {

    var createFolderViewModel: CreateFolderViewModel? {
        didSet {
            breadcrumbs.text = createFolderViewModel?.breadcrumbs
        }
    }

    var completion: ((Folder?) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Create Folder"

        navigationItem.rightBarButtonItem = createButton

        createSubviews()

        keyboardInsetAdjuster = KeyboardInsetAdjuster(scrollView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCreateButton()
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

        let sizeCategory = UITraitCollection.current.preferredContentSizeCategory
        let stack = (sizeCategory <= .extraExtraExtraLarge)
            ? createStacks() : createLargeStacks()

        scrollContentView.addSubview(stack)
        scrollContentView.constrain(stack, top: 16, leading: 16, trailing: 16)

        scrollContentView.addSubview(warningLabel)
        scrollContentView.constrain(warningLabel, leading: 8, bottom: 8, trailing: 8)
        NSLayoutConstraint.activate([
            warningLabel.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20)
        ])
    }

    lazy var createButton: UIBarButtonItem = {
        UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self, action: #selector(createButtonTapped)
        )
    }()

    // Used for lower size categories
    private func createStacks() -> UIView {
        let vstack = UIStackView(arrangedSubviews: [
            nameField,
            breadcrumbs
        ])
        vstack.translatesAutoresizingMaskIntoConstraints = false
        vstack.axis = .vertical
        vstack.alignment = .fill
        vstack.spacing = 3

        let hstack = UIStackView(arrangedSubviews: [
            icon,
            vstack
        ])
        hstack.translatesAutoresizingMaskIntoConstraints = false
        hstack.axis = .horizontal
        hstack.alignment = .center
        hstack.spacing = 16

        return hstack
    }

    // Used for higher size categories
    func createLargeStacks() -> UIView {
        let hstack = UIStackView(arrangedSubviews: [
            icon,
            nameField
        ])
        hstack.translatesAutoresizingMaskIntoConstraints = false
        hstack.axis = .horizontal
        hstack.alignment = .center
        hstack.spacing = 16

        let vstack = UIStackView(arrangedSubviews: [
            hstack,
            breadcrumbs
        ])
        vstack.translatesAutoresizingMaskIntoConstraints = false
        vstack.axis = .vertical
        vstack.alignment = .fill
        vstack.spacing = 6

        breadcrumbs.numberOfLines = 3

        return vstack
    }

    let icon: UIImageView = {
        let icon = UIImageView(image: UIImage.icon(.personalFolder))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.setContentHuggingPriority(.required, for: .horizontal)
        return icon
    }()

    private(set) lazy var nameField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Folder name"
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .done
        field.enablesReturnKeyAutomatically = true

        field.font = .preferredFont(forTextStyle: .body)

        field.delegate = self
        field.addTarget(self, action: #selector(textFieldValueDidChange), for: .editingChanged)

        return field
    }()

    let breadcrumbs: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .caption1)
        return label
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

    private var isCreatingFolder: Bool = false {
        didSet {
            updateCreateButton()
        }
    }
}

// MARK: - Handlers

private extension CreateFolderViewController {
    typealias LocalNameValidationResult = CreateFolderViewModel.LocalNameValidationResult
    func validate(name: String) -> LocalNameValidationResult {
        createFolderViewModel?.validate(name: name) ?? .valid(name: name)
    }

    func updateCreateButton() {
        createButton.isEnabled = canCreateFolder()
    }

    func canCreateFolder() -> Bool {
        guard !isCreatingFolder else {
            return false
        }
        return validatedName(nameField.text ?? "") != nil
    }

    func validatedName(_ name: String) -> String? {
        switch validate(name: nameField.text ?? "") {
        case let .valid(name), let .warning(name, _):
            return name
        case .invalid:
            return nil
        }
    }

    func createFolder(name: String) -> Bool {
        precondition(!isCreatingFolder)
        if let validName = validatedName(name) {
            isCreatingFolder = true
            if validName != nameField.text {
                nameField.text = validName
            }
            createFolderViewModel?.createFolder(
                name: name,
                completion: finishedCreateFolder
            )
            return true
        }
        return false
    }

    func finishedCreateFolder(_ result: Result<Folder, Error>) {
        isCreatingFolder = false
        switch result {
        case let .success(folder):
            completion?(folder)
        case let .failure(error):
            display(error: error.localizedDescription)
        }
    }
}

private extension CreateFolderViewController {
    func display(error: String) {
        warningLabel.text = error
        warningLabel.textColor = UIColor { traits in
            (traits.userInterfaceStyle == .dark) ? #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1) : #colorLiteral(red: 0.3176470697, green: 0.07450980693, blue: 0.02745098062, alpha: 1)
        }
    }

    func display(warning: String) {
        warningLabel.text = warning
        warningLabel.textColor = UIColor { traits in
            (traits.userInterfaceStyle == .dark) ? #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1) : #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)
        }
    }

    func clearError() {
        warningLabel.text = ""
    }
}

// MARK: - UITextFieldDelegate

extension CreateFolderViewController: UITextFieldDelegate {
    @objc
    private func textFieldValueDidChange(_ textField: UITextField) {
        updateCreateButton()
        guard let text = textField.text, !text.isEmpty else {
            clearError()
            return
        }
        switch validate(name: text) {
        case .valid:
            clearError()
        case let .warning(_, reason):
            display(warning: reason)
        case let .invalid(reason):
            display(error: reason)
        }
    }

    @objc
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return createFolder(name: textField.text ?? "")
    }

    @objc
    func createButtonTapped(_: UIBarButtonItem) {
        _ = createFolder(name: nameField.text ?? "")
    }
}

private extension CreateFolderViewController {
    @objc
    func dismissButtonTapped(_: UIBarButtonItem) {
        completion?(nil)
    }
}

// MARK: - Convenience

extension CreateFolderViewController {
    static func forModalPresentation(
        _ viewModel: CreateFolderViewModel,
        completion: @escaping (Folder?) -> Void
    ) -> UINavigationController {
        let viewController = CreateFolderViewController(nibName: nil, bundle: nil)
        viewController.createFolderViewModel = viewModel
        viewController.completion = completion

        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: viewController, action: #selector(dismissButtonTapped)
        )

        return UINavigationController(rootViewController: viewController)
    }
}
