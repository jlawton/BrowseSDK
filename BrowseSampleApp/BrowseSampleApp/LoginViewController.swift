//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import AuthenticationServices
import BoxSDK
import BrowseSDK
import UIKit

class LoginViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    private var sdk: BoxSDK!
    private var client: BoxClient!

    override func viewDidLoad() {
        super.viewDidLoad()

        sdk = BoxSDK(clientId: Constants.clientID, clientSecret: Constants.clientSecret)
    }

    // Handle Box login in the most basic way
    @IBAction private func login(_: UIButton?) {
        sdk.getOAuth2Client(tokenStore: KeychainTokenStore(), context: self) { [weak self] result in
            switch result {
            case let .success(client):
                self?.client = client
                self?.browseRoot()
            case let .failure(error):
                print("error in login: \(error)")
                self?.displayError(error)
            }
        }
    }

    func displayError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Something went wrong",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: "Dismiss",
                style: .default,
                handler: nil
            ))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func browseRoot() {
        client.folders.get(folderId: BoxSDK.Constants.rootFolder, fields: BrowseViewController.requiredFields) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(folder):
                    self.presentBrowser(folder: folder, modal: true)
                case let .failure(error):
                    self.displayError(error)
                }
            }
        }
    }

    private func presentBrowser(folder: Folder, modal: Bool) {
        let config = BrowseConfiguration()

        // Set up the actions that appear top right while browsing folders
//        config.folderActions.disallow([.createFolder])
//        config.folderActions.insertMenu(systemItem: .action) { folder in
//            UIMenu(title: "Share \(folder.name ?? "")", children: self.shareActions(for: folder))
//        }

        // Set up what happens if the user taps a file (rather than a folder).
        // As an example here, we only allow tapping on PDF files, and for those
        // we present an alert.
//        config.browseToFile.forFiles(
//            withExtension: "pdf", permissions: [.preview],
//            .present(fileViewController(for:))
//        )

        if modal {
            let nav = BrowseViewController.browseNavigationController(
                client: client,
                folder: folder,
                withAncestors: true,
                configuration: config,
                withCloseButton: true
            )
            present(nav, animated: true, completion: nil)
        }
        else {

            if let nav = navigationController {
                BrowseViewController.pushBrowseController(
                    client: client,
                    folder: folder,
                    onto: nav,
                    configuration: config
                )
            }
        }
    }

    // Just an example of something to do when a file is tapped.
    private func fileViewController(for file: File) -> UIViewController {
        let alert = UIAlertController(
            title: "Preview File",
            message: "\(file.name!) (\(file.id))",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Dismiss",
            style: .cancel,
            handler: nil
        ))
        return alert
    }

    // Some custom menu actions
    private func shareActions(for folder: Folder) -> [UIAction] {
        var actions: [UIAction] = []

        if folder.permissions?.canShare ?? false {
            actions.append(
                UIAction(
                    title: "Shared Link", image: UIImage(systemName: "link")
                ) { [weak self] _ in
                    let alert = UIAlertController(
                        title: "Share a link", message: nil, preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                    self?.presentedViewController?.present(alert, animated: true, completion: nil)
                }
            )
        }

        if folder.permissions?.canInviteCollaborator ?? false {
            actions.append(
                UIAction(
                    title: "Invite Collaborators", image: UIImage(systemName: "person.crop.circle")
                ) { _ in
                    // Stuff here
                }
            )
        }

        return actions
    }

    // MARK: ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}
