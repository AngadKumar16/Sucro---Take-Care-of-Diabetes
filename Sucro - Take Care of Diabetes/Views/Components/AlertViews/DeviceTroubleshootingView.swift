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
        "Check Bluetooth is enabled in Settings",
        "Ensure transmitter is within 20 feet",
        "Restart the Sucro app",
        "Check for app updates in App Store",
        "Contact support if issues persist"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .symbolEffect(.pulse)
                
                Text("Connection Troubleshooting")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                
                                if index < currentStep {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(index == currentStep ? .white : .primary)
                                }
                            }
                            
                            Text(steps[index])
                                .strikethrough(index < currentStep)
                                .foregroundColor(index < currentStep ? .secondary : .primary)
                            
                            Spacer()
                        }
                        .onTapGesture {
                            withAnimation {
                                currentStep = index + 1
                            }
                        }
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
}