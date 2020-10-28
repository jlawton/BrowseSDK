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
                    self.presentBrowser(folder: folder)
                case let .failure(error):
                    self.displayError(error)
                }
            }
        }
    }

    private func presentBrowser(folder: Folder) {
        var config = BrowseConfiguration()
        config.additionalFields = ["shared_link"]
        config.canSelect = { item in
            switch item {
            case let .folder(folder):
                return (folder.sharedLink != nil)
                    || (folder.permissions?.canShare ?? false)
            case let .file(file):
                return (file.sharedLink != nil)
                    || (file.permissions?.canShare ?? false)
            case let .webLink(link):
                return (link.sharedLink != nil)
                    || (link.permissions?.canShare ?? false)
            }
        }

        let nav = BrowseViewController.browseNavigationController(
            client: client,
            folder: folder,
            configuration: config
        )
        present(nav, animated: true, completion: nil)
    }

    // MARK: ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}
