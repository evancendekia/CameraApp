//
//  FileManagerExtension.swift
//  Camera
//
//  Created by acqmal on 5/7/25.
//

import Foundation

extension FileManager {
    
    var documentDirectory: URL? {
        return self.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    func removeItemFromDocumentDirectory(url: URL) {
        guard let documentDirectory = documentDirectory else { return }
        let fileName = url.lastPathComponent
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        if self.fileExists(atPath: fileURL.path) {
            do {
                try self.removeItem(at: fileURL)
            } catch {
                print("Unable to remove file from document directory: \(error.localizedDescription)")
            }
        }
    }
    
    func getContentsOfDocumentDirectory(_ url: URL) -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return []
        }
        
        do {
            return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        } catch let error {
            print("Unable to get contents of document directory: \(error.localizedDescription)")
        }
        return []
    }
}
