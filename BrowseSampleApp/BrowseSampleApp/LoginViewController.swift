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

        DispatchQueue.main.async {
            if let nav = self.navigationController {
                BrowseViewController.pushBrowseController(client: self.client, onto: nav, browseToFile: selectFile)
            }
        }
    }

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
