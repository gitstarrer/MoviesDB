//
//  BookmarksViewModel.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//

import Foundation

class BookmarksViewModel: ObservableObject {
    @Published var bookmarks: [Bookmark] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    func loadBookmarks() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        let context = coreDataManager.viewContext
        let fetchedBookmarks = await context.perform {
            self.coreDataManager.fetchBookmarks(in: context)
        }
        
        await MainActor.run {
            self.bookmarks = fetchedBookmarks
            self.isLoading = false
        }
    }
    
    func toggleBookmark(movie: Movie) {
        let context = coreDataManager.backgroundContext()
        if coreDataManager.isBookmarked(movieId: movie.id, in: context) {
            coreDataManager.deleteBookmark(movieId: movie.id, in: context)
        } else {
            let bookmark = Bookmark(
                id: movie.id,
                title: movie.title,
                overview: movie.overview,
                posterPath: movie.posterPath,
                releaseDate: movie.releaseDate,
                voteAverage: movie.voteAverage ?? 0,
                timestamp: Date()
            )
            coreDataManager.saveBookmark(bookmark, in: context)
        }
        Task {
            await loadBookmarks() // Refresh bookmarks after toggling
        }
    }
}
