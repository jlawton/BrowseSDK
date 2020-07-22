//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

class KeyboardInsetAdjuster: NSObject {
    weak var scrollView: UIScrollView?

    init(_ scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init()
        startObserving()
    }

    deinit {
        stopObserving()
    }

    private let notificationCenter = NotificationCenter.default
}

private extension KeyboardInsetAdjuster {
    func setInset(_ inset: CGFloat) {
        scrollView?.contentInset.bottom = inset
        scrollView?.verticalScrollIndicatorInsets.bottom = inset
    }

    func startObserving() {
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardDidChangeFrame),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    func stopObserving() {
        notificationCenter.removeObserver(self)
    }

    @objc
    func keyboardWillChangeFrame(_ notification: Notification) {
        changeInsetWithKeyboardChange(notification, animated: true)
    }

    // On iPad, sheets budge up a bit when the keyboard is presented, which means
    // that we don't get the correct covered frame in keyboardWillChangeFrame, so
    // we do the calculation again without animation to fix it up.
    @objc
    func keyboardDidChangeFrame(_ notification: Notification) {
        changeInsetWithKeyboardChange(notification, animated: false)
    }

    func changeInsetWithKeyboardChange(_ notification: Notification, animated: Bool) {
        guard let scrollView = scrollView, let window = scrollView.window else {
            return
        }
        guard let keyboardInfo = KeyboardInfo(userInfo: notification.userInfo) else {
            return
        }

        let scrollViewFrame = window.convert(scrollView.frame, from: scrollView.superview)
        var coveredFrame = scrollViewFrame.intersection(keyboardInfo.endFrame)
        coveredFrame = window.convert(coveredFrame, to: scrollView.superview)

        let safeAreaInset = scrollView.safeAreaInsets.bottom
        let updateInset = { self.setInset(coveredFrame.height - safeAreaInset) }

        if animated {
            keyboardInfo.animateAlongsideKeyboard(updateInset)
        }
        else {
            updateInset()
        }
    }

    @objc
    func keyboardWillHide(_: Notification) {
        setInset(scrollView?.safeAreaInsets.bottom ?? 0)
    }
}

// MARK: - KeyboardInfo

private struct KeyboardInfo {
    let endFrame: CGRect
    let animationOptions: UIView.AnimationOptions
    let animationDuration: TimeInterval

    init?(userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo else {
            return nil
        }
        guard let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return nil
        }

        self.endFrame = endFrame

        // UIViewAnimationOption is shifted by 16 bit from UIViewAnimationCurve, which we get here:
        // http://stackoverflow.com/questions/18870447/how-to-use-the-default-ios7-uianimation-curve
        if let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            animationOptions = UIView.AnimationOptions(rawValue: animationCurve << 16)
        }
        else {
            animationOptions = .curveEaseInOut
        }

        if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            animationDuration = duration
        }
        else {
            animationDuration = 0.25
        }
    }

    func animateAlongsideKeyboard(_ animations: @escaping () -> Void) {
        UIView.animate(
            withDuration: animationDuration,
            delay: 0.0,
            options: animationOptions,
            animations: animations
        )
    }
}
