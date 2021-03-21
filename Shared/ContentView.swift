//
//  ContentView.swift
//  Shared
//
//  Created by SHEN SHENG on 3/21/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Decible.timestamp, ascending: false)],
        animation: .default)
    private var Records: FetchedResults<Decible>

    @ObservedObject var eaves = Eavesdrop()

    var body: some View {
        List {
            ForEach(Records) { record in
                Text("\(record.timestamp!, formatter: itemFormatter): \(record.power) @ \(record.device?.name ?? "unknown device")")
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
            Button(action: trashRecords) {
                    Label("Clean Record", systemImage: "trash")
            }
            Button(action: eaves.Toggle) {
                if eaves.recording {
                    Label("Stop", systemImage: "stop")
                } else {
                    Label("Eavesdrop", systemImage: "record.circle")
                }
            }
            
        }
    }
    
    private func trashRecords() {
        for item in Records {
            viewContext.delete(item)
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Decible(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { Records[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
