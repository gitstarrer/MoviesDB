//
//  NowPlayingMoviesViewModel.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 15/06/25.
//

import Foundation
import Network
import CoreData

class NowPlayingMoviesViewModel: ObservableObject {
    @Published var nowPlayingMovies: [Movie] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isOffline = false
    
    private let apiService: APIServiceProtocol
    private let coreDataManager: CoreDataManager
    private let networkMonitor = NWPathMonitor()
    private let imagePrefetcher = ImagePrefetcher()
    private var nowPlayingPage = 1
    private var canLoadMoreNowPlaying = true
    private var isFetchingNowPlaying = false
    
    init(apiService: APIServiceProtocol, coreDataManager: CoreDataManager) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
        networkMonitor.start(queue: .global(qos: .background))
        // Load data on initialization
        Task {
            await loadNowPlayingMovies()
        }
    }
    
    func loadNowPlayingMovies() async {
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
            
            if coreDataManager.isCacheValid(category: "nowPlaying", in: context) {
                let cachedNowPlaying = await fetchMoviesFromCache(category: "nowPlaying", context: context)
                let uniqueNowPlaying = removeDuplicates(cachedNowPlaying)
                await MainActor.run {
                    self.nowPlayingMovies = uniqueNowPlaying
                }
                await imagePrefetcher.prefetchImages(for: uniqueNowPlaying)
            }
            
            if nowPlayingMovies.isEmpty {
                await MainActor.run {
                    self.error = "No internet connection and no cached now playing movies available."
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            return
        }
        
        do {
            let response = try await apiService.fetchNowPlayingMovies(page: nowPlayingPage)
            let uniqueNowPlaying = removeDuplicates(response.results)
            
            await MainActor.run {
                self.nowPlayingMovies = uniqueNowPlaying
                self.canLoadMoreNowPlaying = response.page < response.totalPages
            }
            
            await imagePrefetcher.prefetchImages(for: uniqueNowPlaying)
            await saveMoviesToCoreData(movies: uniqueNowPlaying, category: "nowPlaying", context: context)
        } catch {
            var cachedNowPlaying: [Movie] = []
            
            if coreDataManager.isCacheValid(category: "nowPlaying", in: context) {
                cachedNowPlaying = await fetchMoviesFromCache(category: "nowPlaying", context: context)
            }
            
            let uniqueNowPlaying = removeDuplicates(cachedNowPlaying)
            
            await MainActor.run {
                if (error as NSError).code == NSURLErrorTimedOut {
                    self.error = "Request timed out. Showing cached now playing movies."
                } else {
                    self.error = "Failed to load now playing movies: \(error.localizedDescription)"
                }
                self.nowPlayingMovies = uniqueNowPlaying
            }
            
            if !uniqueNowPlaying.isEmpty {
                await imagePrefetcher.prefetchImages(for: uniqueNowPlaying)
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func prefetchMoreNowPlayingMovies() async {
        guard !isFetchingNowPlaying, canLoadMoreNowPlaying else { return }
        isFetchingNowPlaying = true
        
        guard networkMonitor.currentPath.status == .satisfied else {
            await MainActor.run {
                self.error = "No internet connection. Showing cached now playing movies."
            }
            isFetchingNowPlaying = false
            return
        }
        
        do {
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
        } catch {
            await MainActor.run {
                if (error as NSError).code == NSURLErrorTimedOut {
                    self.error = "Request timed out. Showing cached now playing movies."
                } else {
                    self.error = "Failed to load more now playing movies: \(error.localizedDescription)"
                }
            }
        }
        
        isFetchingNowPlaying = false
    }
    
    private func resetState() async {
        await MainActor.run {
            self.nowPlayingMovies = []
            self.nowPlayingPage = 1
            self.canLoadMoreNowPlaying = true
            self.isFetchingNowPlaying = false
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
