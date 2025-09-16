//
//  CGPoint+Distance.swift
//  union-buttons
//
//  Created by Ben Sage on 9/16/25.
//

import Foundation

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
