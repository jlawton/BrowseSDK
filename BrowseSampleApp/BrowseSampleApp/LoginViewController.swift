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
        // Set up what happens if the user taps a file (rather than a folder).
        // As an example here, we only allow tapping on PDF files, and for those
        // we present an alert.
        let selectFile = BrowseToFile(
            canBrowseToFile: { (file) -> Bool in
                (file.permissions?.canDownload ?? false)
                    && (file.name?.lowercased().hasSuffix("pdf") ?? false)
            },
            browseToFile: { (file: File, fromVC: UIViewController) -> SelectionBehavior in
                let dest = self.fileViewController(for: file)
                fromVC.present(dest, animated: true, completion: nil)
                return .deselect
            }
        )

        // Push a file browser onto our navigation controller. The browser will
        // continue to push view controllers onto the navigation stack as the
        // user taps on folders, but if a file is tapped, we do what is defined
        // above.
        DispatchQueue.main.async {
            if let nav = self.navigationController {
                BrowseViewController.pushBrowseController(
                    client: self.client,
                    onto: nav,
                    browseToFile: selectFile)
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

    // MARK: ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}
