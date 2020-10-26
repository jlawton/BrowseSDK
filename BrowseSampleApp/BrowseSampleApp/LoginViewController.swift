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
        let config = BrowseConfiguration()

        // Set up what happens if the user taps a file (rather than a folder).
        // As an example here, we only allow tapping on PDF files, and for those
        // we present an alert.
//        config.browseToFile.forFiles(
//            withExtension: "pdf", permissions: [.preview],
//            .present(fileViewController(for:))
//        )

        let nav = BrowseViewController.browseNavigationController(
            client: client,
            folder: folder,
            withAncestors: true,
            configuration: config,
            withCloseButton: true
        )
        present(nav, animated: true, completion: nil)
    }

    // MARK: ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}
