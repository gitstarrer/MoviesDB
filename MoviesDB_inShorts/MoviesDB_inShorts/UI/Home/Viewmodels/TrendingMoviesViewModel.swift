//
//  TrendingMoviesViewModel.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 15/06/25.
//

import Foundation
import Network
import CoreData

class TrendingMoviesViewModel: ObservableObject {
    @Published var trendingMovies: [Movie] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isOffline = false
    
    private let apiService: APIServiceProtocol
    private let coreDataManager: CoreDataManager
    private let networkMonitor = NWPathMonitor()
    private let imagePrefetcher = ImagePrefetcher()
    private var trendingPage = 1
    private var canLoadMoreTrending = true
    private var isFetchingTrending = false
    
    init(apiService: APIServiceProtocol, coreDataManager: CoreDataManager) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
        networkMonitor.start(queue: .global(qos: .background))
        // Load data on initialization
        Task {
            await loadTrendingMovies()
        }
    }
    
    func loadTrendingMovies() async {
        // Reset state for a fresh load
        await resetState()
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
            self.isOffline = false
        }
        
        let context = coreDataManager.backgroundContext()
        
        if networkMonitor.currentPath.status != .satisfied {
            await MainActor.run {
                self.isOffline = true
            }
            
            if coreDataManager.isCacheValid(category: "trending", in: context) {
                let cachedTrending = await fetchMoviesFromCache(category: "trending", context: context)
                let uniqueTrending = removeDuplicates(cachedTrending)
                await MainActor.run {
                    self.trendingMovies = uniqueTrending
                }
                await imagePrefetcher.prefetchImages(for: uniqueTrending)
            }
            
            if trendingMovies.isEmpty {
                await MainActor.run {
                    self.error = "No internet connection and no cached trending movies available."
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            return
        }
        
        do {
            let response = try await apiService.fetchTrendingMovies(page: trendingPage)
            let uniqueTrending = removeDuplicates(response.results)
            
            await MainActor.run {
                self.trendingMovies = uniqueTrending
                self.canLoadMoreTrending = response.page < response.totalPages
            }
            
            await imagePrefetcher.prefetchImages(for: uniqueTrending)
            await saveMoviesToCoreData(movies: uniqueTrending, category: "trending", context: context)
        } catch {
            var cachedTrending: [Movie] = []
            
            if coreDataManager.isCacheValid(category: "trending", in: context) {
                cachedTrending = await fetchMoviesFromCache(category: "trending", context: context)
            }
            
            let uniqueTrending = removeDuplicates(cachedTrending)
            
            await MainActor.run {
                if (error as NSError).code == NSURLErrorTimedOut {
                    self.error = "Request timed out. Showing cached trending movies."
                } else {
                    self.error = "Failed to load trending movies: \(error.localizedDescription)"
                }
                self.trendingMovies = uniqueTrending
            }
            
            if !uniqueTrending.isEmpty {
                await imagePrefetcher.prefetchImages(for: uniqueTrending)
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func prefetchMoreTrendingMovies() async {
        guard !isFetchingTrending, canLoadMoreTrending else { return }
        isFetchingTrending = true
        
        guard networkMonitor.currentPath.status == .satisfied else {
            await MainActor.run {
                self.error = "No internet connection. Showing cached trending movies."
            }
            isFetchingTrending = false
            return
        }
        
        do {
            trendingPage += 1
            let response = try await apiService.fetchTrendingMovies(page: trendingPage)
            let newMovies = response.results
            let uniqueMovies = removeDuplicates(trendingMovies + newMovies)
            
            await MainActor.run {
                self.trendingMovies = uniqueMovies
                self.canLoadMoreTrending = response.page < response.totalPages
            }
            
            await imagePrefetcher.prefetchImages(for: newMovies)
            await saveMoviesToCoreData(movies: newMovies, category: "trending", context: coreDataManager.backgroundContext())
        } catch {
            await MainActor.run {
                if (error as NSError).code == NSURLErrorTimedOut {
                    self.error = "Request timed out. Showing cached trending movies."
                } else {
                    self.error = "Failed to load more trending movies: \(error.localizedDescription)"
                }
            }
        }
        
        isFetchingTrending = false
    }
    
    private func resetState() async {
        await MainActor.run {
            self.trendingMovies = []
            self.trendingPage = 1
            self.canLoadMoreTrending = true
            self.isFetchingTrending = false
        }
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
