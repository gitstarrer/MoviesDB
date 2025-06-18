//
//  SearchViewModel.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//

import Foundation
import Network
import CoreData

class SearchViewModel: ObservableObject {
    @Published var popularMovies: [Movie] = []
    @Published var searchResults: [Movie] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isOffline = false // New state to indicate offline mode
    
    private let apiService: APIServiceProtocol
    private let coreDataManager: CoreDataManager
    private let networkMonitor = NWPathMonitor()
    private var searchPage = 1
    private var canLoadMore = true
    private var isFetching = false
    
    init(apiService: APIServiceProtocol, coreDataManager: CoreDataManager) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    func loadDefaultMovies() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
            self.isOffline = false
        }
        
        let context = coreDataManager.backgroundContext()
        
        // Check if offline
        if networkMonitor.currentPath.status != .satisfied {
            await MainActor.run {
                self.isOffline = true
            }
            
            // Load cached popular movies
            if coreDataManager.isCacheValid(category: "popular", in: context) {
                let cachedPopular = await fetchMoviesFromCache(category: "popular", context: context)
                let uniquePopular = removeDuplicates(cachedPopular)
                await MainActor.run {
                    self.popularMovies = uniquePopular
                }
            }
            
            // If no cached data, show an error
            if popularMovies.isEmpty {
                await MainActor.run {
                    self.error = "No internet connection and no cached popular movies available."
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            return // Exit early since we're offline
        }
        
        // If online, fetch from API
        do {
            let response = try await apiService.fetchPopularMovies(page: 1)
            let uniquePopular = removeDuplicates(response.results)
            
            await MainActor.run {
                self.popularMovies = uniquePopular
            }
            
            await saveMoviesToCoreData(movies: uniquePopular, category: "popular", context: context)
        } catch {
            var cachedPopular: [Movie] = []
            
            if coreDataManager.isCacheValid(category: "popular", in: context) {
                cachedPopular = await fetchMoviesFromCache(category: "popular", context: context)
            }
            
            let uniquePopular = removeDuplicates(cachedPopular)
            
            await MainActor.run {
                if (error as NSError).code == NSURLErrorTimedOut {
                    self.error = "Request timed out. Showing cached popular movies."
                } else {
                    self.error = "Failed to load popular movies: \(error.localizedDescription)"
                }
                
                self.popularMovies = uniquePopular
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func searchMovies(query: String) async {
        guard !query.isEmpty else {
            await loadDefaultMovies()
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
            self.searchResults = []
            self.searchPage = 1
            self.canLoadMore = true
        }
        
        guard networkMonitor.currentPath.status == .satisfied else {
            await MainActor.run {
                self.error = "No internet connection. Search is unavailable offline."
                self.isLoading = false
            }
            return
        }
        
        do {
            let response = try await apiService.searchMovies(query: query, page: searchPage)
            let uniqueResults = removeDuplicates(response.results)
            
            await MainActor.run {
                self.searchResults = uniqueResults
                self.canLoadMore = response.page < response.totalPages
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to search movies: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func loadMoreMovies() async {
        guard !isFetching, canLoadMore else { return }
        isFetching = true
        
        guard networkMonitor.currentPath.status == .satisfied else {
            await MainActor.run {
                self.error = "No internet connection. Cannot load more movies."
            }
            isFetching = false
            return
        }
        
        do {
            searchPage += 1
            let response = try await apiService.searchMovies(query: searchResultsQuery(), page: searchPage)
            let newResults = response.results
            let uniqueResults = removeDuplicates(searchResults + newResults)
            
            await MainActor.run {
                self.searchResults = uniqueResults
                self.canLoadMore = response.page < response.totalPages
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load more movies: \(error.localizedDescription)"
            }
        }
        
        isFetching = false
    }
    
    private func searchResultsQuery() -> String {
        // Assuming searchQuery is stored or passed; for simplicity, return a placeholder
        return "query" // Replace with actual query logic if needed
    }
    
    private func fetchMoviesFromCache(category: String, context: NSManagedObjectContext) async -> [Movie] {
        await withCheckedContinuation { continuation in
            context.perform {
                let movies = self.coreDataManager.fetchMovies(category: category, in: context)
                continuation.resume(returning: movies)
            }
        }
    }
    
    private func saveMoviesToCoreData(movies: [Movie], category: String, context: NSManagedObjectContext) async {
        await withCheckedContinuation { continuation in
            self.coreDataManager.saveMovies(movies, category: category, in: context)
            continuation.resume()
        }
    }
    
    private func removeDuplicates(_ movies: [Movie]) -> [Movie] {
        var seenIds = Set<Int>()
        return movies.filter { movie in
            if seenIds.contains(movie.id) {
                return false
            } else {
                seenIds.insert(movie.id)
                return true
            }
        }
    }
}
