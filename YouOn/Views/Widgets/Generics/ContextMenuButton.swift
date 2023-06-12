//
//  ContextMenuButton.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 12.06.2023.
//

import Foundation
import UIKit

class ContextMenuButton: UIButton {
    
    var previewProvider: UIContextMenuContentPreviewProvider?
    
    var actionProvider: UIContextMenuActionProvider?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        let interaction = UIContextMenuInteraction(delegate: self)
        addInteraction(interaction)
    }

    public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: previewProvider,
            actionProvider: actionProvider
        )
    }
}
