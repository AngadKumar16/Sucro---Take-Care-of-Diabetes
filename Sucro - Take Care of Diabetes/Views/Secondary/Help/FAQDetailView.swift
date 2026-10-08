//
//  FAQDetailView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

struct FAQDetailView: View {
    let article: HelpArticle

    var body: some View {
        ScrollView {
            Text(article.body)
                .font(.body)
                .lineSpacing(3)
                .frame(maxWidth: 640, alignment: .leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
