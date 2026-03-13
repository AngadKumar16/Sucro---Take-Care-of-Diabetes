//
//  EditInsulinView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI

struct EditInsulinView: View {
    @ObservedObject var entry: InsulinEntry
    
    // Explicit custom bindings
    private var typeBinding: Binding<String> {
        Binding(
            get: { entry.type ?? "rapid" },
            set: { entry.type = $0 }
        )
    }
    
    private var deliveryMethodBinding: Binding<String> {
        Binding(
            get: { entry.deliveryMethod ?? "pen" },
            set: { entry.deliveryMethod = $0 }
        )
    }
    
    private var timestampBinding: Binding<Date> {
        Binding(
            get: { entry.timestamp ?? Date() },
            set: { entry.timestamp = $0 }
        )
    }
    
    private var notesBinding: Binding<String> {
        Binding(
            get: { entry.notes ?? "" },
            set: { entry.notes = $0.isEmpty ? nil : $0 }
        )
    }
    
    var body: some View {
        Form {
            Section("Insulin Details") {
                Picker("Type", selection: typeBinding) {
                    Text("Rapid Acting").tag("rapid")
                    Text("Long Acting").tag("long")
                    Text("Intermediate").tag("intermediate")
                }
                
                Picker("Delivery Method", selection: deliveryMethodBinding) {
                    Text("Pen").tag("pen")
                    Text("Pump").tag("pump")
                    Text("Syringe").tag("syringe")
                }
                
                HStack {
                    Text("Units")
                    Spacer()
                    // units is non-optional Double, so use $entry.units directly
                    TextField("Units", value: $entry.units, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                DatePicker("Time", selection: timestampBinding)
            }
            
            Section("Notes") {
                TextEditor(text: notesBinding)
                    .frame(height: 100)
            }
        }
    }
}
