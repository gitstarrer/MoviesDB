//
//  MovieCardView.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 15/06/25.
//


import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    @State private var isBookmarked: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let posterPath = movie.posterPath,
                   let url = URL(string: "\(APIConfiguration.imageBaseURL)\(posterPath)") {
                    CachedImageView(url: url, cache: ImagePrefetcher.sharedCache)
                        .accessibilityLabel("Poster for \(movie.title)")
                } else {
                    ProgressView()
                        .frame(width: 120, height: 205)
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.1))
                        .accessibilityLabel("No poster available for \(movie.title)")
                }

                Button(action: {
                    isBookmarked.toggle()
                    bookmarksViewModel.toggleBookmark(movie: movie)
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(6)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
        }
        .onAppear {
            isBookmarked = bookmarksViewModel.bookmarks.contains(where: { $0.id == movie.id })
        }
    }
}
