//
//  DeviceTroubleshootingView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  DeviceTroubleshootingView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI

struct DeviceTroubleshootingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var currentStep = 0
    
    let steps = [
        "Check your CGM app is showing current readings",
        "Make sure Bluetooth is on and your phone is near the sensor",
        "If you log readings yourself, add your latest one in the Log tab",
        "Close DiabetesCare and open it again",
        "Still stuck? Contact support"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                    .symbolEffect(.pulse)
                
                Text("No Recent Readings")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Button {
                            completeStep(index)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                        .frame(width: 28, height: 28)
                                    
                                    if index < currentStep {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .bold()
                                            .foregroundStyle(index == currentStep ? .white : .primary)
                                    }
                                }
                                
                                Text(steps[index])
                                    .strikethrough(index < currentStep)
                                    .foregroundStyle(index < currentStep ? .secondary : .primary)
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                
                Spacer()
                
                Button("Contact Support", systemImage: "envelope") {
                    if let url = AppInfo.supportEmailURL {
                        openURL(url)
                    }
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .padding()
            .navigationTitle("Troubleshooting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func completeStep(_ index: Int) {
        withAnimation {
            currentStep = index + 1
        }
    }
}
