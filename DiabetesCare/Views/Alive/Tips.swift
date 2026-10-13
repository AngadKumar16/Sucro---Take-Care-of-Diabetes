//
//  Tips.swift
//  DiabetesCare
//
//  First-time hints for gestures that are easy to miss. Each shows until
//  the person does the thing once, then goes away for good.
//

import SwiftUI
import TipKit

struct SavedMealsTip: Tip {
    var title: Text { Text("Saved Meals") }
    var message: Text? { Text("Touch and hold Log Meal to log breakfast, lunch or dinner in one tap.") }
    var image: Image? { Image(systemName: "hand.tap") }
}

struct LogSwipeTip: Tip {
    var title: Text { Text("Edit or Delete") }
    var message: Text? { Text("Tap an entry to edit it. Swipe left to delete it.") }
    var image: Image? { Image(systemName: "hand.draw") }
}

struct ChartScrubTip: Tip {
    var title: Text { Text("Explore the Chart") }
    var message: Text? { Text("Drag across the chart to see each reading and what you logged around it.") }
    var image: Image? { Image(systemName: "hand.point.up.left") }
}

struct YourPathTip: Tip {
    var title: Text { Text("Grow Your Plant") }
    var message: Text? { Text("Learn skills and collect stickers to open new features and help your plant grow.") }
    var image: Image? { Image(systemName: "leaf") }
}

struct FoodSearchTip: Tip {
    var title: Text { Text("Look Up Carbs") }
    var message: Text? { Text("Search thousands of foods, or scan a package's barcode, to fill in the carbs.") }
    var image: Image? { Image(systemName: "magnifyingglass") }
}

enum AppTips {
    /// Called once at launch. UI tests and screenshots hide every tip so
    /// they don't cover what the test taps.
    static func configure(hidden: Bool) {
        if hidden { Tips.hideAllTipsForTesting() }
        try? Tips.configure([.displayFrequency(.immediate)])
    }
}
