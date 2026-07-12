//
//  ContentView.swift
//  Ask Numi
//

import SwiftUI

struct ContentView: View {
    let container: AppContainer

    var body: some View {
        // ponytail: dashboard still renders preview data; wire a
        // HomeDashboardViewModel through the container when the screen goes live.
        HomeDashboardView(snapshot: .preview)
    }
}

#Preview {
    ContentView(container: AppContainer())
}
