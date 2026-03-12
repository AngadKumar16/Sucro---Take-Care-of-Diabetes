//
//  ContentView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "timestamp", ascending: true)],
        animation: .default)
    private var readings: FetchedResults<GlucoseReading>

    var body: some View {
        NavigationView {
            List {
                ForEach(readings) { reading in
                    NavigationLink {
                        Text("Glucose: \(reading.value) \(reading.unit ?? "mg/dL")")
                    } label: {
                        HStack {
                            Text("\(reading.value, specifier: "%.0f")")
                                .foregroundColor(reading.value > 180 ? .red : reading.value < 70 ? .orange : .green)
                            Text(reading.unit ?? "mg/dL")
                                .foregroundColor(.secondary)
                            Spacer()
                            if let timestamp = reading.timestamp {
                                Text(timestamp, formatter: itemFormatter)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteReadings)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addReading) {
                        Label("Add Reading", systemImage: "plus")
                    }
                }
            }
            Text("Select a reading")
        }
    }

    private func addReading() {
        withAnimation {
            let newReading = GlucoseReading(context: viewContext)
            newReading.id = UUID()
            newReading.timestamp = Date()
            newReading.value = 100.0
            newReading.unit = "mg/dL"

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteReadings(offsets: IndexSet) {
        withAnimation {
            offsets.map { readings[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
