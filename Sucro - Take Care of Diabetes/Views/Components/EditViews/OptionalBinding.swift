//
//  OptionalBindings.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI

// MARK: - Extensions for direct Optional values (String?, Date?)
// Use these when you have: @State var name: String?

extension Optional where Wrapped == String {
    var bound: Binding<String> {
        Binding(
            get: { self ?? "" },
            set: { self = $0 }
        )
    }
}

extension Optional where Wrapped == Date {
    var bound: Binding<Date> {
        Binding(
            get: { self ?? Date() },
            set: { self = $0 }
        )
    }
}

// MARK: - Extensions for Binding to Optional values (Binding<String?>, Binding<Date?>)
// Use these when you have: @ObservedObject var entry: SomeObject
// and you access: $entry.someOptionalProperty

extension Binding where Value == String? {
    var bound: Binding<String> {
        Binding(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

extension Binding where Value == Date? {
    var bound: Binding<Date> {
        Binding(
            get: { self.wrappedValue ?? Date() },
            set: { self.wrappedValue = $0 }
        )
    }
}
