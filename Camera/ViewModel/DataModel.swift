//
//  DataModel.swift
//  Camera
//
//  Created by acqmal on 5/7/25.
//

import Foundation

class DataModel: ObservableObject {
    @Published var items: [Item] = []
    
    init() {
        getItem()
    }
    
    func getItem() {
        items = getImageFromDocumentsDirectory()
    }
    
    func addItem(_ item: Item) {
        items.insert(item, at: 0)
    }
    
    func removeItem(_ item: Item) {
        if let index = items.firstIndex(of: item) {
            items.remove(at: index)
            FileManager.default.removeItemFromDocumentDirectory(url: item.url)
        }
    }
    
    
    private func getImageFromDocumentsDirectory() -> [Item] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            var fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.creationDateKey])
            fileURLs = fileURLs.filter { $0.isImage }
            fileURLs.sort { ($0.creation ?? .distantPast) > ($1.creation ?? .distantPast) }
            
            return fileURLs.map { Item(url: $0, creationDate: $0.creation) }
            
        } catch {
            print("Error loading images: \(error)")
            return []
        }
    }
}

