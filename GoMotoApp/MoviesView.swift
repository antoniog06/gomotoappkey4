//
//  MoviesView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.

import SwiftUI
import WebKit
// MARK: - Main Movies View
struct MoviesView: View {
    @StateObject private var youtubeService = YouTubeService()
    @State private var searchQuery = "free full movies"
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // ✅ Use a struct conforming to Identifiable for the selected video
    @State private var selectedVideo: SelectedVideo?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 🎯 Enhanced Search Bar
                SearchBar(
                    text: $searchQuery,
                    onSearch: { youtubeService.fetchMovies(query: searchQuery) }
                )
                .padding()
                .background(Color(.systemGray6))

                // 🌟 Recommendations Button with Haptic Feedback
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    youtubeService.fetchMovies(query: "best free movies recommendations")
                }) {
                    Label("Explore Recommendations", systemImage: "star.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)

                // 🎬 Movie Grid with Animated Transitions
                ScrollView {
                    if youtubeService.isLoading {
                        LoadingView()
                    } else if youtubeService.movies.isEmpty {
                        EmptyStateView(retryAction: {
                            youtubeService.fetchMovies(query: searchQuery)
                        })
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 160), spacing: 15)],
                            spacing: 15
                        ) {
                            ForEach(youtubeService.movies, id: \.id.videoId) { movie in
                                MovieCard(movie: movie, onSelect: {
                                    selectedVideo = SelectedVideo(id: movie.id.videoId)
                                })
                            }
                        }
                        .padding()
                        .animation(.easeInOut, value: youtubeService.movies)
                    }
                }
            }
            .navigationTitle("Movie Explorer 🎬")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { youtubeService.fetchMovies(query: searchQuery) }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                youtubeService.fetchMovies(query: searchQuery)
            }
            // ✅ Use `.sheet` with Identifiable wrapper
            .sheet(item: $selectedVideo) { video in
                YouTubePlayerView(videoID: video.id)
            }
        }
    }
}

// ✅ Wrapper for Identifiable Video ID
struct SelectedVideo: Identifiable {
    let id: String
}

/*import SwiftUI
import AVKit

// MARK: - Main Movies View
struct MoviesView: View {
    @StateObject private var youtubeService = YouTubeService()
    @State private var searchQuery = "free full movies"
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var videoID = "dQw4w9WgXcQ"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced Search Bar
                SearchBar(
                    text: $searchQuery,
                    onSearch: { youtubeService.fetchMovies(query: searchQuery) }
                )
                .padding()
                .background(Color(.systemGray6))
                
                // Recommendations Button with Haptic Feedback
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    youtubeService.fetchMovies(query: "best free movies recommendations")
                }) {
                    Label("Explore Recommendations", systemImage: "star.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Movie Grid with Empty State
                ScrollView {
                    if youtubeService.isLoading {
                        LoadingView()
                    } else if youtubeService.movies.isEmpty {
                        EmptyStateView(retryAction: {
                            youtubeService.fetchMovies(query: searchQuery)
                        })
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 160), spacing: 15)],
                            spacing: 15
                        ) {
                            ForEach(youtubeService.movies, id: \.id.videoId) { movie in
                                MovieCard(movie: movie)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                        .animation(.easeInOut, value: youtubeService.movies)
                    }
                }
            }
            .navigationTitle("Movie Explorer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { youtubeService.fetchMovies(query: searchQuery) }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                youtubeService.fetchMovies(query: searchQuery)
            }
        }
    }
}*/

// MARK: - Animated & Enhanced Search Bar
struct SearchBar: View {
    @Binding var text: String
    let onSearch: () -> Void
    @State private var isTyping: Bool = false
    @State private var animatedText: String = "Search movies..."
    @State private var gradientColors: [Color] = [.blue, .purple]
    @State private var isAnimatingGradient: Bool = false // Control gradient animation state
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(animatedText)
                        .foregroundStyle(.gray.opacity(0.6))
                        .fontWeight(.medium)
                        .fontDesign(.rounded) // Modern, rounded font for a softer look
                        .transition(.opacity.combined(with: .scale))
                        .animation(
                            .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: animatedText
                        )
                }
                
                TextField("", text: $text, onEditingChanged: { editing in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isTyping = editing
                        if editing {
                            // Shrink the button dynamically when typing starts
                            isAnimatingGradient = true
                        } else {
                            isAnimatingGradient = false
                        }
                    }
                }, onCommit: onSearch)
                .foregroundStyle(.primary)
                .font(.body)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.thinMaterial) // Use thin material for a modern, translucent effect
                        .shadow(color: isTyping ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.gray.opacity(0.2), lineWidth: 1)
                )
                .accessibilityLabel("Search movies input")
                .accessibilityHint("Type to search movies, then press return or the search button to submit")
                .accessibilityValue(text.isEmpty ? animatedText : text)
            }
            
            // Enhanced Animated Magnifying Glass Button
            Button(action: {
                onSearch()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.4)) {
                    gradientColors = [Color.blue, Color.purple, Color.teal].shuffled()
                    isAnimatingGradient = true
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: isTyping ? 24 : 48, height: isTyping ? 24 : 48)
                    .foregroundStyle(.white)
                    .padding(isTyping ? 8 : 12)
                    .background(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(isAnimatingGradient ? 1.0 : 0.8)
                    )
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.4), radius: 4, x: 0, y: 2)
                    .animation(.easeInOut(duration: 0.5), value: isTyping) // Smooth scaling animation
            }
            .accessibilityLabel("Search button")
            .accessibilityHint("Tap to search for movies")
            .buttonStyle(.plain) // Ensure plain style for custom animations
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .onAppear {
            // Optimized placeholder text animation with better performance
            let words = ["Search movies...", "Find free films 🎬", "Explore trending videos!"]
            var index = 0
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedText = words[index]
                }
                index = (index + 1) % words.count
            }
        }
    }
}

// ✅ Ensure MovieCard takes an `onSelect` closure
struct MovieCard: View {
    let movie: YouTubeMovie
    let onSelect: () -> Void  // Accepts a closure

    var body: some View {
        Button(action: {
            onSelect() // ✅ Calls the callback when tapped
        }) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: movie.snippet.thumbnails.medium.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .foregroundColor(.gray)
                            .cornerRadius(8)
                    case .empty:
                        ProgressView()
                            .frame(height: 120)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                Text(movie.snippet.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 4)
        }
    }
}
/*struct MovieCard: View {
    let movie: YouTubeMovie
    
    var body: some View {
        NavigationLink(destination: YouTubePlayerView(videoID: movie.id.videoId)) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: movie.snippet.thumbnails.medium.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .frame(height: 120)
                    case .empty:
                        ProgressView()
                            .frame(height: 120)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                Text(movie.snippet.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 4)
        }
    }
}*/

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading Movies...")
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct EmptyStateView: View {
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "film")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No movies found")
                .font(.title3)
            Button("Try Again", action: retryAction)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.top, 50)
    }
}



// MARK: - Models (Updated with Equatable and Safe Decoding)
struct YouTubeMovie: Codable, Equatable {
    struct ID: Codable, Equatable {
        let videoId: String
    }
    
    struct Snippet: Codable, Equatable {
        struct ThumbnailContainer: Codable, Equatable {
            struct Thumbnail: Codable, Equatable {
                let url: String
            }
            let medium: Thumbnail
        }
        
        let title: String
        let thumbnails: ThumbnailContainer
    }

    let id: ID
    let snippet: Snippet
    
    // ✅ Implement Equatable conformance
    static func == (lhs: YouTubeMovie, rhs: YouTubeMovie) -> Bool {
        return lhs.id.videoId == rhs.id.videoId
    }
}

// MARK: - Extension for Safe Decoding (Prevents Crashes)
extension YouTubeMovie {
    init?(json: [String: Any]) {
        guard let idDict = json["id"] as? [String: Any],
              let videoId = idDict["videoId"] as? String,
              let snippetDict = json["snippet"] as? [String: Any],
              let title = snippetDict["title"] as? String,
              let thumbnailsDict = snippetDict["thumbnails"] as? [String: Any],
              let mediumDict = thumbnailsDict["medium"] as? [String: Any],
              let thumbnailUrl = mediumDict["url"] as? String else {
            return nil
        }

        self.id = ID(videoId: videoId)
        self.snippet = Snippet(
            title: title,
            thumbnails: Snippet.ThumbnailContainer(medium: Snippet.ThumbnailContainer.Thumbnail(url: thumbnailUrl))
        )
    }
}




