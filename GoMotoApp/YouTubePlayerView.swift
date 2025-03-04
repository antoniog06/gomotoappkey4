//
//  YouTubePlayerView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//

import SwiftUI
import YouTubeiOSPlayerHelper

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> YTPlayerView {
        let playerView = YTPlayerView()
        playerView.load(withVideoId: videoID)
        return playerView
    }
    
    func updateUIView(_ uiView: YTPlayerView, context: Context) {}
}

    
    
   


