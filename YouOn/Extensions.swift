//
//  Extensions.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import UIKit

extension String {
    func getYoutubeID() -> String? {
        let pattern = #"(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)"#
        if let matchRange = self.range(of: pattern, options: .regularExpression) {
            return String(self[matchRange])
        } else {
            return .none
        }
    }
}

extension Encodable {
    func saveAsJsonData() -> Data? {
        do {
            let encoded = try JSONEncoder().encode(self)
            return encoded
        } catch {
            return nil
        }
    }
}
