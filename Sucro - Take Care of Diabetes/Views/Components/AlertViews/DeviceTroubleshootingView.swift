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
    @State private var currentStep = 0
    
    let steps = [
        "Make sure Bluetooth is on in Settings",
        "Keep your phone within 20 feet of the transmitter",
        "Close Sucro and open it again",
        "Update Sucro from the App Store",
        "Still stuck? Contact support"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse)
                
                Text("Connection Troubleshooting")
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
                
                Button("Contact Support") {
                    if let url = URL(string: "mailto:support@sucro.app") {
                        UIApplication.shared.open(url)
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("Troubleshooting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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
