//
//  ContentView.swift
//  Nafas
//
//  Created by Rana Alngashy on 15/03/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("say_welcome")
                .appFont(size: 30)

        }
        .padding()
    }
}

#Preview("Arabic"){
    ContentView()
        .environment(\.locale, .init(identifier: "ar"))
}
