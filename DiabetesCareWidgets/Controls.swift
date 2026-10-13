//
//  Controls.swift
//  DiabetesCareWidgets
//
//  Control Center, Lock Screen and Action button controls that open the
//  app straight to logging or to Get Help.
//

import AppIntents
import SwiftUI
import WidgetKit

struct LogCarbsControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.AngadKumar16.DiabetesCare.logCarbs") {
            ControlWidgetButton(action: OpenRouteIntent(screen: .logCarbs)) {
                Label("Log Carbs", systemImage: "fork.knife")
            }
        }
        .displayName("Log Carbs")
        .description("Opens DiabetesCare to log a meal.")
    }
}

struct LogGlucoseControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.AngadKumar16.DiabetesCare.logGlucose") {
            ControlWidgetButton(action: OpenRouteIntent(screen: .logGlucose)) {
                Label("Log Glucose", systemImage: "drop.fill")
            }
        }
        .displayName("Log Glucose")
        .description("Opens DiabetesCare to log a reading.")
    }
}

struct GetHelpControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.AngadKumar16.DiabetesCare.getHelp") {
            ControlWidgetButton(action: OpenRouteIntent(screen: .getHelp)) {
                Label("Get Help", systemImage: "hand.raised.fill")
            }
        }
        .displayName("Get Help With a Low")
        .description("Opens the steps for a low and who to call.")
    }
}
