//
//  HomeViewModel.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//

import Foundation
import Network
import CoreData

class HomeViewModel: ObservableObject {
    @Published var trendingMovies: [Movie] = []
    @Published var nowPlayingMovies: [Movie] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isOffline = false
    
    private let apiService: APIServiceProtocol
    private let coreDataManager: CoreDataManager
    private let networkMonitor = NWPathMonitor()
    private let imagePrefetcher = ImagePrefetcher()
    private var trendingPage = 1
    private var nowPlayingPage = 1
    private var canLoadMoreTrending = true
    private var canLoadMoreNowPlaying = true
    private var isFetchingTrending = false
    private var isFetchingNowPlaying = false
    
    init(apiService: APIServiceProtocol, coreDataManager: CoreDataManager) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    func loadMovies() async {
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
            
            // Load cached data for trending movies
            if coreDataManager.isCacheValid(category: "trending", in: context) {
                let cachedTrending = await fetchMoviesFromCache(category: "trending", context: context)
                let uniqueTrending = removeDuplicates(cachedTrending)
                await MainActor.run {
                    self.trendingMovies = uniqueTrending
                }
                await imagePrefetcher.prefetchImages(for: uniqueTrending)
            }
            
            // Load cached data for now playing movies
            if coreDataManager.isCacheValid(category: "nowPlaying", in: context) {
                let cachedNowPlaying = await fetchMoviesFromCache(category: "nowPlaying", context: context)
                let uniqueNowPlaying = removeDuplicates(cachedNowPlaying)
                await MainActor.run {
                    self.nowPlayingMovies = uniqueNowPlaying
                }
                await imagePrefetcher.prefetchImages(for: uniqueNowPlaying)
            }
            
            // If no cached data, show an error
            if trendingMovies.isEmpty && nowPlayingMovies.isEmpty {
                await MainActor.run {
                    self.error = "No internet connection and no cached data available."
                }
            }
            
            // Stop loading since we're offline
            await MainActor.run {
                self.isLoading = false
            }
            return // Exit early since we're offline
        }
        
        // If online, fetch from API
        do {
            async let trendingResponse = apiService.fetchTrendingMovies(page: trendingPage)
            async let nowPlayingResponse = apiService.fetchNowPlayingMovies(page: nowPlayingPage)
            
            let (trending, nowPlaying) = try await (trendingResponse, nowPlayingResponse)
            let uniqueTrending = removeDuplicates(trending.results)
            let uniqueNowPlaying = removeDuplicates(nowPlaying.results)
            
            await MainActor.run {
                self.trendingMovies = uniqueTrending
                self.nowPlayingMovies = uniqueNowPlaying
                self.canLoadMoreTrending = trending.page < trending.totalPages
                self.canLoadMoreNowPlaying = nowPlaying.page < nowPlaying.totalPages
            }
            
            await imagePrefetcher.prefetchImages(for: uniqueTrending)
            await imagePrefetcher.prefetchImages(for: uniqueNowPlaying)
            
            await saveMoviesToCoreData(movies: uniqueTrending, category: "trending", context: context)
            await saveMoviesToCoreData(movies: uniqueNowPlaying, category: "nowPlaying", context: context)
        } catch {
            // Perform async operations outside MainActor.run
            var cachedTrending: [Movie] = []
            var cachedNowPlaying: [Movie] = []
            
            if coreDataManager.isCacheValid(category: "trending", in: context) {
                cachedTrending = await fetchMoviesFromCache(category: "trending", context: context)
            }
            
            if coreDataManager.isCacheValid(category: "nowPlaying", in: context) {
                cachedNowPlaying = await fetchMoviesFromCache(category: "nowPlaying", context: context)
            }
            
            let uniqueTrending = removeDuplicates(cachedTrending)
            let uniqueNowPlaying = removeDuplicates(cachedNowPlaying)
            
            // Now perform synchronous UI updates
            await MainActor.run {
                if (error as NSError).code == NSURLErrorTimedOut {
                    self.error = "Request timed out. Showing cached movies."
                } else {
                    self.error = "Failed to load movies: \(error.localizedDescription)"
                }
                
                self.trendingMovies = uniqueTrending
                self.nowPlayingMovies = uniqueNowPlaying
            }
            
            // Perform image prefetching outside MainActor.run
            if !uniqueTrending.isEmpty {
                await imagePrefetcher.prefetchImages(for: uniqueTrending)
            }
            if !uniqueNowPlaying.isEmpty {
                await imagePrefetcher.prefetchImages(for: uniqueNowPlaying)
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func prefetchMoreMovies(category: String) async {
        if category == "trending" {
            guard !isFetchingTrending, canLoadMoreTrending else { return }
            isFetchingTrending = true
        } else {
            guard !isFetchingNowPlaying, canLoadMoreNowPlaying else { return }
            isFetchingNowPlaying = true
        }
        
        guard networkMonitor.currentPath.status == .satisfied else {
            await MainActor.run {
                self.error = "No internet connection. Showing cached data."
            }
            if category == "trending" {
                isFetchingTrending = false
            } else {
                isFetchingNowPlaying = false
            }
            return
        }
        
        do {
            if category == "trending" {
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
            } else {
                nowPlayingPage += 1
                let response = try await apiService.fetchNowPlayingMovies(page: nowPlayingPage)
                let newMovies = response.results
                let uniqueMovies = removeDuplicates(nowPlayingMovies + newMovies)
                await MainActor.run {
                    self.nowPlayingMovies = uniqueMovies
                    self.canLoadMoreNowPlaying = response.page < response.totalPages
                }
                await imagePrefetcher.prefetchImages(for: newMovies)
                await saveMoviesToCoreData(movies: newMovies, category: "nowPlaying", context: coreDataManager.backgroundContext())
            }
        } catch {
            await MainActor.run {
                if (error as NSError).code == NSURLErrorTimedOut {
                    self.error = "Request timed out. Showing cached movies."
                } else {
                    self.error = "Failed to load more movies: \(error.localizedDescription)"
                }
            }
        }
        
        if category == "trending" {
            isFetchingTrending = false
        } else {
            isFetchingNowPlaying = false
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
