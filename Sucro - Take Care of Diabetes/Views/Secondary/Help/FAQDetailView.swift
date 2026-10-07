//
//  FAQDetailView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

struct FAQDetailView: View {
    let article: HelpArticle
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title)
                    .font(.title2)
                    .bold()
                
                Text(article.body)
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
