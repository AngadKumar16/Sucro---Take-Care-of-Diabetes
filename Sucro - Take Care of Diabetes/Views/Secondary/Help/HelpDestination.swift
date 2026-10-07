//
//  HelpDestination.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// Screens pushed from Help.
enum HelpDestination: Hashable {
    case article(HelpArticle)
    case safety
}
