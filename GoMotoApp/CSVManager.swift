//
//  CSVManager.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/8/25.
//
import Foundation
import SwiftUI

class CSVManager {
    static func loadCSVFile() {
        if let filePath = Bundle.main.path(forResource: "default", ofType: "csv") {
            do {
                let fileContents = try String(contentsOfFile: filePath)
                print(fileContents) // Process the data here
            } catch {
                print("Error reading file: \(error.localizedDescription)")
            }
        } else {
            print("File not found.")
        }
    }
}
