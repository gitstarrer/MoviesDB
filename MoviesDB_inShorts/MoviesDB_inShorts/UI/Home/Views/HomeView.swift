//
//  HomeView.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var trendingViewModel = TrendingMoviesViewModel(apiService: APIService(), coreDataManager: .shared)
    @StateObject private var nowPlayingViewModel = NowPlayingMoviesViewModel(apiService: APIService(), coreDataManager: .shared)
    @ObservedObject var bookmarkViewModel: BookmarksViewModel
    
    @State private var lastTrendingCount = 0
    @State private var lastNowPlayingCount = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if trendingViewModel.isOffline || nowPlayingViewModel.isOffline {
                        Text("Offline Mode: Please check your internet connection and try again.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .accessibilityLabel("Offline mode: showing cached movies")
                    }
                    
                    TrendingSection(
                        viewModel: trendingViewModel,
                        bookmarksViewModel: bookmarkViewModel,
                        lastCount: $lastTrendingCount
                    )
                    NowPlayingSection(
                        nowPlayingViewModel: nowPlayingViewModel,
                        bookmarksViewModel: bookmarkViewModel,
                        lastCount: $lastNowPlayingCount
                    )
                    
                    if trendingViewModel.isLoading || nowPlayingViewModel.isLoading {
                        ProgressView()
                            .padding()
                            .accessibilityLabel("Loading movies")
                    }
                    
                    if let error = trendingViewModel.error ?? nowPlayingViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .accessibilityLabel("Error: \(error)")
                    }
                }
            }
            .navigationTitle("MoviesDB")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                async let trendingTask: () = trendingViewModel.loadTrendingMovies()
                async let nowPlayingTask: () = nowPlayingViewModel.loadNowPlayingMovies()
                await bookmarkViewModel.loadBookmarks()
                _ = await (trendingTask, nowPlayingTask)
            }
        }
    }
}

struct CachedImageView: View {
    let url: URL
    @StateObject private var imageLoader: ImageLoader
    
    init(url: URL, cache: NSCache<NSURL, UIImage> = ImagePrefetcher.sharedCache) {
        self.url = url
        self._imageLoader = StateObject(wrappedValue: ImageLoader(cache: cache))
    }
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .frame(width: 120, height: 205)
                    .foregroundColor(.gray)
                    .background(Color.gray.opacity(0.1))
            }
        }
        .task(id: url) {
            await imageLoader.load(from: url)
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let cache: NSCache<NSURL, UIImage>
    
    init(cache: NSCache<NSURL, UIImage>) {
        self.cache = cache
    }
    
    func load(from url: URL) async {
        if let cachedImage = cache.object(forKey: url as NSURL) {
            await MainActor.run {
                self.image = cachedImage
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data) else { return }
            
            cache.setObject(uiImage, forKey: url as NSURL)
            
            await MainActor.run {
                self.image = uiImage
            }
        } catch {
            print("Failed to load image from \(url): \(error)")
        }
    }
}

struct TapAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
