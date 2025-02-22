//
//  FlowerLabelerApp.swift
//  FlowerLabeler
//
//  Created by David Gadling on 2/22/25.
//

import SwiftUI

@main
struct FlowerLabelerApp: App {
    var body: some Scene {
        WindowGroup {
            LabelingView()
                .frame(minWidth: 1024, minHeight: 768)
        }
    }
}
