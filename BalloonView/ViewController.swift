//
//  BalloonView.swift
//  BalloonView
//
//  Created by teddy on 11/12/18.
//  Copyright © 2018 merpay, Inc. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var dogOneLabel: UILabel!
    @IBOutlet private weak var dogTwoLabel: UILabel!
    @IBOutlet private weak var catLabel: UILabel!
    @IBOutlet private weak var dogThreeLabel: UILabel!
    @IBOutlet private weak var dogFourLabel: UILabel!
    private lazy var grayOverlay: UIView = { (grayOverlay: UIView) in
        grayOverlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.16)
        return grayOverlay
    }(UIView(frame: .zero))

    private enum Tutorial {
        case zero, one
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showTutorial(.zero)
    }

    @IBAction private func tappedButton(_ sender: Any) {
        showTutorial(.one)
    }

    private func showTutorial(_ tutorial: Tutorial) {
        func showTutorialFlowZero() {
            let tutorialZeroBalloon = tutorialZeroBalloonView()
            let chain = tutorialZeroBalloon.onTapped({ [weak self] inputBalloonView in
                inputBalloonView?.dismiss()
                self?.hideGrayOverlay { }
                return nil
            })
            tutorialZeroBalloon.show(onTapped: chain)
        }
        func showTutorialFlowOne() {
            let tutorialBalloon = tutorialOneBalloonView()
            let chain = tutorialBalloon.onTapped({ inputBalloonView in
                inputBalloonView?.dismiss()
                return tutorialTwoBalloonView()
            }) >>> { inputBalloonView in
                inputBalloonView?.dismiss()
                return tutorialThreeBalloonView()
            } >>> { inputBalloonView in
                inputBalloonView?.dismiss()
                return tutorialFourBalloonView()
            } >>> { inputBalloonView in
                inputBalloonView?.dismiss()
                return tutorialFiveBalloonView()
            } >>> { [weak self] inputBalloonView in
                inputBalloonView?.dismiss()
                self?.hideGrayOverlay { }
                return nil
            }
            tutorialBalloon.show(onTapped: chain)
        }

        func tutorialZeroBalloonView() -> BalloonView {
            let contentView = TutorialView(frame: .zero)
            contentView.title = "Flowey:"
            contentView.body = "Let's learn about dogs!"
            contentView.image = #imageLiteral(resourceName: "flowey")
            contentView.bottomText = "OK!"
            return BalloonView(contentView: contentView,
                               forView: button,
                               withinSuperview: view)
        }
        func tutorialOneBalloonView() -> BalloonView {
            let contentView = TutorialView(frame: .zero)
            contentView.title = "Dog:"
            contentView.body = "Hi! I'm a dog! I have dog friends!"
            contentView.image = #imageLiteral(resourceName: "Annoying_Dog")
            return BalloonView(contentView: contentView,
                               forView: dogOneLabel,
                               withinSuperview: view)
        }
        func tutorialTwoBalloonView() -> BalloonView {
            let contentView = TutorialView(frame: .zero)
            contentView.title = "Dog:"
            contentView.body = "I'm also a dog"
            contentView.image = #imageLiteral(resourceName: "greater_dog")
            return BalloonView(contentView: contentView,
                               forView: dogTwoLabel,
                               withinSuperview: view)
        }
        func tutorialThreeBalloonView() -> BalloonView {
            let contentView = TutorialView(frame: .zero)
            contentView.title = "Dog:"
            contentView.body = "I'm a dog too"
            contentView.image = #imageLiteral(resourceName: "lesser_dog")
            return BalloonView(contentView: contentView,
                               forView: dogThreeLabel,
                               withinSuperview: view)
        }
        func tutorialFourBalloonView() -> BalloonView {
            let contentView = TutorialView(frame: .zero)
            contentView.title = "Dog:"
            contentView.body = "I'm a dog too"
            contentView.image = #imageLiteral(resourceName: "Annoying_Dog")
            return BalloonView(contentView: contentView,
                               forView: dogFourLabel,
                               withinSuperview: view)
        }
        func tutorialFiveBalloonView() -> BalloonView {
            let contentView = TutorialView(frame: .zero)
            contentView.title = "Dog?"
            contentView.body = "Am I a dog?"
            contentView.bottomText = "Done"
            contentView.image = #imageLiteral(resourceName: "temmie")
            return BalloonView(contentView: contentView,
                               forView: catLabel,
                               withinSuperview: view)
        }

        showGrayOverlay {
            switch tutorial {
            case .zero: showTutorialFlowZero()
            case .one: showTutorialFlowOne()
            }
        }
    }

    private func showGrayOverlay(completion: @escaping () -> Void) {
        grayOverlay.alpha = 0
        view.addSubview(grayOverlay)
        grayOverlay.translatesAutoresizingMaskIntoConstraints = false
        grayOverlay.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        grayOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        grayOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        grayOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        UIView.animate(withDuration: 0.1, animations: { [weak grayOverlay] in
            grayOverlay?.alpha = 1
        }) { _ in
            completion()
        }
    }

    private func hideGrayOverlay(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, animations: { [weak grayOverlay] in
            grayOverlay?.alpha = 0
        }) { [weak grayOverlay] _ in
            grayOverlay?.removeFromSuperview()
            completion()
        }
    }
}
