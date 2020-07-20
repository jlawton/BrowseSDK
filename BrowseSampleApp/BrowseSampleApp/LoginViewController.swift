//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import AuthenticationServices
import BoxSDK
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
                // DO SOMETHING
            case let .failure(error):
                print("error in login: \(error)")
                self?.displayError(error)
            }
        }
    }

    func displayError(_ error: Error) {
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
        present(alert, animated: true, completion: nil)
    }

    // MARK: ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}
