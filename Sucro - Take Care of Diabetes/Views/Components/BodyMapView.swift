//
//  BodyMapView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

struct BodyMapView: View {
    let selectedLocation: String
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Body Outline
            ZStack {
                // Body shape
                Ellipse()
                    .fill(Color.gray.opacity(0.2))
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: 120, height: 200)
                
                // Site markers
                ForEach(SiteLocation.allCases, id: \.self) { location in
                    Circle()
                        .fill(location == SiteLocation(rawValue: selectedLocation) ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 12, height: 12)
                        .position(
                            x: 60 + (location.coordinates.x * 100),
                            y: 40 + (location.coordinates.y * 160)
                        )
                        .onTapGesture {
                            onTap()
                        }
                }
            }
            .frame(width: 120, height: 200)
            
            // Location Legend
            VStack(alignment: .leading, spacing: 4) {
                Text("Current: \(selectedLocation)")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("Tap to change")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        BodyMapView(selectedLocation: "Abdomen Left") {
            print("Tapped body map")
        }
        
        BodyMapView(selectedLocation: "Thigh Right") {
            print("Tapped body map")
        }
    }
    .padding()
}
