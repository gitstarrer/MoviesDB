//
//  NowPlayingSection.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 15/06/25.
//

import SwiftUI

struct NowPlayingSection: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingMoviesViewModel
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    
    @Binding var lastCount: Int
    @State private var shouldPrefetch = false
    @State private var isInitialLoad = true
    
    private let nowPlayingColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Now Playing")
                .font(.title2.bold())
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)
            
            ScrollViewReader { proxy in
                LazyVGrid(columns: nowPlayingColumns, spacing: 10) {
                    ForEach(Array(nowPlayingViewModel.nowPlayingMovies.enumerated()), id: \.element.id) { index, movie in
                        NavigationLink {
                            MovieDetailView(movie: movie,
                                            bookmarkViewModel: bookmarksViewModel)
                        } label: {
                            MovieCardView(movie: movie,
                                          bookmarksViewModel: bookmarksViewModel)
                        }
                        .buttonStyle(TapAnimationButtonStyle())
                    }
                    
                    Color.clear
                        .frame(height: 50) // Increase height to trigger earlier
                        .id("end-of-list")
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .global).minY)
                            }
                        )
                }
                .padding(.horizontal)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { minY in
                    let screenHeight = UIScreen.main.bounds.height
                    if minY < screenHeight * 1.5 && !shouldPrefetch && nowPlayingViewModel.nowPlayingMovies.count > 0 {
                        shouldPrefetch = true
                        Task {
                            await nowPlayingViewModel.prefetchMoreNowPlayingMovies()
                            shouldPrefetch = false
                        }
                    }
                }
                .onChange(of: nowPlayingViewModel.nowPlayingMovies.count) { newCount in
                    if newCount < lastCount {
                        lastCount = newCount
                        isInitialLoad = true
                    } else {
                        lastCount = newCount
                        isInitialLoad = false
                        // Removed forced scroll to bottom
                    }
                }
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
