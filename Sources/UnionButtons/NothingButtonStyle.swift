//
//  NothingButtonStyle.swift
//  Patrol
//
//  Created by Ben Sage on 11/19/24.
//

import SwiftUI

public struct NothingButtonStyle: ButtonStyle {
    public init() { }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

public extension ButtonStyle where Self == NothingButtonStyle {
    static var nothing: NothingButtonStyle { .init() }
}
