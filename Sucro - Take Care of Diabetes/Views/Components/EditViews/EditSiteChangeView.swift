//
//  EditSiteChangeView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI

struct EditSiteChangeView: View {
    @ObservedObject var entry: SiteChange
    
    // Explicit custom bindings - no extension needed
    private var locationBinding: Binding<String> {
        Binding(
            get: { entry.location ?? "abdomen" },
            set: { entry.location = $0 }
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
            Section("Site Details") {
                Picker("Location", selection: locationBinding) {
                    Text("Abdomen").tag("abdomen")
                    Text("Arm").tag("arm")
                    Text("Thigh").tag("thigh")
                    Text("Buttocks").tag("buttocks")
                }
                
                DatePicker("Change Time", selection: timestampBinding)
            }
            
            Section("Notes") {
                TextEditor(text: notesBinding)
                    .frame(height: 100)
            }
        }
    }
}
