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
        var config = BrowseConfiguration()

        // Set up the actions that appear top right while browsing folders
//        config.folderActions.disallow([.createFolder])
        config.folderActions.insertMenu(systemItem: .action) { folder in
            UIMenu(title: "Share \(folder.name ?? "")", children: self.shareActions(for: folder))
        }

        // Set up what happens if the user taps a file (rather than a folder).
        // As an example here, we only allow tapping on PDF files, and for those
        // we present an alert.
        config.browseToFile.forFiles(
            withExtension: "pdf", permissions: [.download],
            .present(fileViewController(for:))
        )

        // Push a file browser onto our navigation controller. The browser will
        // continue to push view controllers onto the navigation stack as the
        // user taps on folders, but if a file is tapped, we do what is defined
        // above.
        DispatchQueue.main.async {
            // TODO: Remove this hack!
            let rootFolder = try? Folder(json: [
                "id": BoxSDK.Constants.rootFolder,
                "type": "folder",
                "name": "All Files",
                "path_collection": [
                    "entries": []
                ]
            ])
            guard let folder = rootFolder else {
                return
            }
            #if true
                let nav = BrowseViewController.browseNavigationController(
                    client: self.client,
                    folder: folder,
                    withAncestors: true,
                    configuration: config,
                    withCloseButton: true
                )
                self.present(nav, animated: true, completion: nil)
            #else
                if let nav = self.navigationController {
                    BrowseViewController.pushBrowseController(
                        client: self.client,
                        folder: folder,
                        onto: nav,
                        configuration: config
                    )
                }
            #endif
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

    private func shareActions(for folder: Folder) -> [UIAction] {
        var actions: [UIAction] = []

        if folder.permissions?.canShare ?? false {
            actions.append(
                UIAction(
                    title: "Shared Link", image: UIImage(systemName: "link")
                ) { _ in
                    // Stuff here
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
