//
//  TrendingSection.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 15/06/25.
//

import SwiftUI

struct TrendingSection: View {
    @ObservedObject var viewModel: TrendingMoviesViewModel
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    @Binding var lastCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trending Movies")
                .font(.title2.bold())
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(Array(viewModel.trendingMovies.enumerated()), id: \.element.id) { index, movie in
                        NavigationLink {
                            MovieDetailView(movie: movie,
                                            bookmarkViewModel: bookmarksViewModel)
                        } label: {
                            TrendingMovieCard(movie: movie,
                                              bookmarksViewModel: bookmarksViewModel)
                        }
                        .buttonStyle(TapAnimationButtonStyle())
                        .onAppear {
                            let prefetchThreshold = 5
                            if viewModel.trendingMovies.count > lastCount &&
                                index == viewModel.trendingMovies.count - prefetchThreshold - 1 {
                                Task { await viewModel.prefetchMoreTrendingMovies() }
                                lastCount = viewModel.trendingMovies.count
                            }
                        }
                    }
                }
                .padding()
                .onChange(of: viewModel.trendingMovies.count) {
                    let newCount = viewModel.trendingMovies.count
                    if newCount < lastCount {
                        lastCount = viewModel.trendingMovies.count
                    }
                }
            }
        }
    }
}

struct TrendingMovieCard: View {
    let movie: Movie
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    @State private var isBookmarked: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let posterPath = movie.posterPath,
                   let url = URL(string: "\(APIConfiguration.imageBaseURL)\(posterPath)") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 250, height: 360)
                                .background(Color.gray.opacity(0.1))
                        case .success(let image):
                            image
                                .resizable()
                                .frame(width: 250, height: 360)
                                .scaledToFill()
                                .shadow(radius: 3)
                                .accessibilityLabel("Poster for \(movie.title)")
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 250, height: 360)
                                .scaledToFit()
                                .foregroundColor(.gray)
                                .background(Color.gray.opacity(0.1))
                                .accessibilityLabel("Failed to load poster for \(movie.title)")
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 250, height: 360)
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("No poster available for \(movie.title)")
                }
                
                Button(action: {
                    isBookmarked.toggle()
                    bookmarksViewModel.toggleBookmark(movie: movie)
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .padding(8)
                }
                .padding(6)
            }
            
            Text(movie.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .frame(maxWidth: 250)
            
            
            if let releaseDate = movie.formattedReleaseDate {
                Text(releaseDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .frame(maxWidth: 250)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 4)
        .onAppear {
            isBookmarked = bookmarksViewModel.bookmarks.contains(where: { $0.id == movie.id })
        }
    }
}
