//
//  SafetyInfoView.swift
//  DiabetesCare
//

import SwiftUI

struct SafetyInfoView: View {
    var body: some View {
        ScrollView {
            SafetyNoticeContent()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .instrumentBackground()
        .navigationTitle("Safety Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}
