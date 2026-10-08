//
//  GlossaryCategoryIcon.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// The rounded colored tile used for topics, like a Settings icon.
struct GlossaryCategoryIcon: View {
    let category: GlossaryCategory
    @ScaledMetric(relativeTo: .body) private var size = 30

    var body: some View {
        Image(systemName: category.symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(category.color.gradient, in: .rect(cornerRadius: size * 0.25))
            .accessibilityHidden(true)
    }
}
