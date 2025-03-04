//
//  YouTubeService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//

import Foundation
import SwiftUI

// MARK: - Service
class YouTubeService: ObservableObject  {
    @Published var movies: [YouTubeMovie] = []
    @Published var isLoading: Bool = false
    
    private let apiKey = "AIzaSyCuE1ZnYq5PpkaVMqXNuC7CETT28ZWFybU" // Replace with actual key
    private let cache = NSCache<NSString, NSArray>()
    
    func fetchMovies(query: String) {
        let cacheKey = NSString(string: query)
        if let cachedMovies = cache.object(forKey: cacheKey) as? [YouTubeMovie] {
            movies = cachedMovies
            return
        }
        
        isLoading = true
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=\(encodedQuery)&maxResults=20&key=\(apiKey)") else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                self.handleError("Server error: \(httpResponse.statusCode)")
                return
            }
            
            guard let data = data, error == nil else {
                self.handleError(error?.localizedDescription ?? "Network error")
                return
            }
            
            do {
                let response = try JSONDecoder().decode(YouTubeResponse.self, from: data)
                let movies = response.items ?? []
                DispatchQueue.main.async {
                    self.movies = movies
                    self.cache.setObject(movies as NSArray, forKey: cacheKey)
                }
            } catch {
                self.handleError("Failed to parse response: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func handleError(_ message: String) {
        DispatchQueue.main.async {
            // In a real app, you'd trigger an alert here
            print("Error: \(message)")
        }
    }
}


