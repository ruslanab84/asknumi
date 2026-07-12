//
//  Ask_NumiApp.swift
//  Ask Numi
//
//  Created by Ruslan Abdulov on 12.07.26.
//

import SwiftUI

@main
struct Ask_NumiApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
    }
}
