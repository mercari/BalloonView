//
//  TutorialBuyPointsView.swift
//  BalloonView
//
//  Created by teddy on 11/12/18.
//  Copyright © 2018 merpay, Inc. All rights reserved.
//

import UIKit

final class TutorialView: NibInstantiableView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var bottomLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    var title: String? {
        didSet { titleLabel.text = title}
    }
    var body: String? {
        didSet { bodyLabel.text = body }
    }
    var image: UIImage? {
        didSet { imageView.image = image }
    }
    var bottomText: String? {
        didSet { bottomLabel.text = bottomText }
    }
}

open class NibInstantiableView: UIView {

    @objc public private(set) var nibView: UIView!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        instantiateNibView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let view = aDecoder.decodeObject(forKey: #keyPath(nibView)) as? UIView {
            nibView = view
        } else {
            instantiateNibView()
        }
    }

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(nibView, forKey: #keyPath(nibView))
    }

    private func instantiateNibView() {
        let nibName = String(describing: type(of: self))
        guard let view = UINib(nibName: nibName, bundle: Bundle(for: type(of: self)))
            .instantiate(withOwner: self, options: nil)
            .compactMap({ $0 as? UIView })
            .first else {
                fatalError("\(nibName) not found")
        }

        frame = view.bounds
        addSubview(view)

        nibView = view

        nibView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                nibView.topAnchor.constraint(equalTo: topAnchor),
                nibView.leftAnchor.constraint(equalTo: leftAnchor),
                nibView.rightAnchor.constraint(equalTo: rightAnchor),
                nibView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        )
    }
}
