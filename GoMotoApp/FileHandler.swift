//
//  FileHandler.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/12/25.
//


import Foundation
import SwiftUI

class FileHandler {
    static func selectCSVFile(completion: @escaping (String?) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = keyWindow.rootViewController else {
            print("Unable to access rootViewController")
            completion(nil)
            return
        }

        let csvPicker = UIHostingController(rootView: CSVFilePickerView { url in
            readCSVFile(at: url, completion: completion)
        })

        rootViewController.present(csvPicker, animated: true)
    }

    static func readCSVFile(at url: URL, completion: @escaping (String?) -> Void) {
        do {
            let data = try String(contentsOf: url)
            completion(data)
        } catch {
            print("Failed to read file: \(error.localizedDescription)")
            completion(nil)
        }
    }
}