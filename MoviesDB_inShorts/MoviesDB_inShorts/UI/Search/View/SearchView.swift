//
//  SearchView.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 15/06/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel(apiService: APIService(), coreDataManager: .shared)
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    
    @State private var searchQuery = ""
    @State private var searchTask: Task<Void, Never>?
    
    private let searchColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                content
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search movies")
            .onChange(of: searchQuery) {
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    guard !Task.isCancelled else { return }
                    await viewModel.searchMovies(query: searchQuery)
                }
            }
            .task {
                await viewModel.loadDefaultMovies()
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.searchResults.isEmpty && !viewModel.isLoading && searchQuery.isEmpty {
            popularMoviesView
        } else if viewModel.searchResults.isEmpty && !searchQuery.isEmpty && !viewModel.isLoading {
            Text("No results found for \"\(searchQuery)\"")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding()
        } else {
            searchResultsView
        }
    }
    
    private var popularMoviesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Popular Movies")
                    .font(.title2.bold())
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)
                
                LazyVGrid(columns: searchColumns, spacing: 10) {
                    ForEach(viewModel.popularMovies) { movie in
                        navigationLink(for: movie)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVGrid(columns: searchColumns, spacing: 10) {
                ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, movie in
                    navigationLink(for: movie)
                        .onAppear {
                            let threshold = 5
                            if index == viewModel.searchResults.count - threshold - 1 {
                                Task { await viewModel.loadMoreMovies() }
                            }
                        }
                }
            }
            .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .accessibilityLabel("Loading search results")
            }
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }

    private func navigationLink(for movie: Movie) -> some View {
        NavigationLink {
            MovieDetailView(movie: movie, bookmarkViewModel: bookmarksViewModel)
        } label: {
            MovieCardView(movie: movie, bookmarksViewModel: bookmarksViewModel)
        }
        .buttonStyle(TapAnimationButtonStyle())
    }
}
