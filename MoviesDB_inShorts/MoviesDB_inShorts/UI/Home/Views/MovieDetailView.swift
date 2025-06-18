//
//  MovieDetailView.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 15/06/25.
//

import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @ObservedObject var bookmarkViewModel: BookmarksViewModel
    @State private var isBookmarked: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack(alignment: .topTrailing) {
                    if let posterPath = movie.posterPath,
                       let url = URL(string: "\(APIConfiguration.imageBaseURL)\(posterPath)") {
                        CachedImageView(url: url)
                            .frame(height: 520)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                            .accessibilityLabel("Poster for \(movie.title)")
                    } else {
                        Color.gray
                            .overlay(
                                Image(systemName: "film")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                            )
                            .frame(height: 500)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                            .accessibilityLabel("No poster available for \(movie.title)")
                    }
                    
                    Button(action: {
                        isBookmarked.toggle()
                        bookmarkViewModel.toggleBookmark(movie: movie)
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(.white)
                            .shadow(radius: 8)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 36)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(movie.title)
                        .font(.title.bold())
                        .accessibilityAddTraits(.isHeader)
                    
                    HStack(spacing: 15) {
                        if let releaseDate = movie.formattedReleaseDate {
                            Label(releaseDate, systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let voteAverage = movie.voteAverage {
                            Label(String(format: "%.1f/10", voteAverage), systemImage: "star.fill")
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text("Overview")
                        .font(.title3.bold())
                        .padding(.top, 5)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(movie.overview.isEmpty ? "No overview available." : movie.overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Overview: \(movie.overview.isEmpty ? "No overview available." : movie.overview)")
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .onAppear {
                isBookmarked = bookmarkViewModel.bookmarks.contains(where: { $0.id == movie.id })
            }
        }
        .navigationTitle(movie.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
