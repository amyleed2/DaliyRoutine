//
//  ContentView.swift
//  DailyRoutine
//
//  Created by ezyeun on 11/19/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            print("ci/cd 테스트")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
