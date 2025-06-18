//
//  BookmarksView.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//

import SwiftUI

struct BookmarksView: View {
    @ObservedObject var viewModel: BookmarksViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.bookmarks.isEmpty && !viewModel.isLoading {
                    Text("No bookmarked movies yet.")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding()
                        .accessibilityLabel("No bookmarked movies yet")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(viewModel.bookmarks) { bookmark in
                                let movie = Movie(
                                    id: bookmark.id,
                                    title: bookmark.title,
                                    overview: bookmark.overview,
                                    posterPath: bookmark.posterPath,
                                    releaseDate: bookmark.releaseDate,
                                    voteAverage: bookmark.voteAverage
                                )

                                NavigationLink {
                                    MovieDetailView(movie: movie, bookmarkViewModel: viewModel)
                                } label: {
                                    MovieCardView(movie: movie, bookmarksViewModel: viewModel)
                                }
                                .buttonStyle(TapAnimationButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .accessibilityLabel("Loading bookmarks")
                }

                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .accessibilityLabel("Error: \(error)")
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                 await viewModel.loadBookmarks()
            }
        }
    }
}
