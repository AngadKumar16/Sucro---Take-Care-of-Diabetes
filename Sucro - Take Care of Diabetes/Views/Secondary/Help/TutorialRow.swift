//
//  TutorialRow.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

struct TutorialRow: View {
    let title: String
    let duration: String
    
    var body: some View {
        HStack {
            Image(systemName: "book.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
