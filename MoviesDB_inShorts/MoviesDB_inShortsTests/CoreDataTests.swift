//
//  CoreDataTests.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//


import Testing
import CoreData
@testable import MoviesDB_inShorts

struct CoreDataManagerTests {
    var coreDataManager: CoreDataManager!
    var persistentContainer: NSPersistentContainer!
    
    @Test("Save and Fetch Movies")
    func testSaveAndFetchMovies() {
        let context = coreDataManager.backgroundContext()
        let movies = [sampleMovie()]
        let category = "nowPlaying"
        
        coreDataManager.saveMovies(movies, category: category, in: context)
        
        let fetchedMovies = coreDataManager.fetchMovies(category: category, in: context)
        
        #expect(fetchedMovies.count == 1)
        #expect(fetchedMovies[0].id == movies[0].id)
        #expect(fetchedMovies[0].title == movies[0].title)
        #expect(fetchedMovies[0].overview == movies[0].overview)
        #expect(fetchedMovies[0].posterPath == movies[0].posterPath)
        #expect(fetchedMovies[0].releaseDate == movies[0].releaseDate)
        #expect(fetchedMovies[0].voteAverage == movies[0].voteAverage)
    }
    
    @Test("Check Cache Validity - Valid Cache")
    func testIsCacheValidWhenCacheIsRecent() {
        let context = coreDataManager.backgroundContext()
        let movies = [sampleMovie()]
        let category = "nowPlaying"
        
        coreDataManager.saveMovies(movies, category: category, in: context)
        
        let isValid = coreDataManager.isCacheValid(category: category, in: context)
        #expect(isValid == true)
    }
    
    @Test("Check Cache Validity - Expired Cache")
    func testIsCacheValidWhenCacheIsExpired() {
        let context = coreDataManager.backgroundContext()
        let movies = [sampleMovie()]
        let category = "nowPlaying"
        
        coreDataManager.saveMovies(movies, category: category, in: context)
        
        // Manually update the lastUpdated timestamp to be older than 24 hours
        let fetchRequest: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        if let entity = try? context.fetch(fetchRequest).first {
            entity.lastUpdated = Date(timeIntervalSinceNow: -25 * 60 * 60) // 25 hours ago
            coreDataManager.saveContext(context)
        }
        
        let isValid = coreDataManager.isCacheValid(category: category, in: context)
        #expect(isValid == false)
    }
    
    @Test("Save and Fetch Bookmarks")
    func testSaveAndFetchBookmarks() {
        let context = coreDataManager.backgroundContext()
        let bookmark = sampleBookmark()
        
        coreDataManager.saveBookmark(bookmark, in: context)
        
        let fetchedBookmarks = coreDataManager.fetchBookmarks(in: context)
        
        #expect(fetchedBookmarks.count == 1)
        #expect(fetchedBookmarks[0].id == bookmark.id)
        #expect(fetchedBookmarks[0].title == bookmark.title)
        #expect(fetchedBookmarks[0].overview == bookmark.title)
        #expect(fetchedBookmarks[0].posterPath == bookmark.posterPath)
        #expect(fetchedBookmarks[0].releaseDate == bookmark.releaseDate)
        #expect(fetchedBookmarks[0].voteAverage == bookmark.voteAverage)
        #expect(fetchedBookmarks[0].timestamp == bookmark.timestamp)
    }
    
    @Test("Check If Movie Is Bookmarked")
    func testIsBookmarked() {
        let context = coreDataManager.backgroundContext()
        let bookmark = sampleBookmark(id: 1)
        
        coreDataManager.saveBookmark(bookmark, in: context)
        
        let isBookmarked = coreDataManager.isBookmarked(movieId: 1, in: context)
        #expect(isBookmarked == true)
        
        let isNotBookmarked = coreDataManager.isBookmarked(movieId: 2, in: context)
        #expect(isNotBookmarked == false)
    }
    
    @Test("Delete Bookmark")
    func testDeleteBookmark() {
        let context = coreDataManager.backgroundContext()
        let bookmark = sampleBookmark(id: 1)
        
        coreDataManager.saveBookmark(bookmark, in: context)
        
        var isBookmarked = coreDataManager.isBookmarked(movieId: 1, in: context)
        #expect(isBookmarked == true)
        
        coreDataManager.deleteBookmark(movieId: 1, in: context)
        
        isBookmarked = coreDataManager.isBookmarked(movieId: 1, in: context)
        #expect(isBookmarked == false)
    }
    
    init() {
        persistentContainer = NSPersistentContainer(name: "MoviesApp")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        
        coreDataManager = CoreDataManager()
        let mirror = Mirror(reflecting: coreDataManager)
        for child in mirror.children {
            if child.label == "persistentContainer" {
                if let container = child.value as? NSPersistentContainer {
                    container.persistentStoreDescriptions = [description]
                    container.loadPersistentStores { _, error in
                        if let error = error {
                            fatalError("Failed to load in-memory store for CoreDataManager: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func sampleMovie(id: Int = 1) -> Movie {
        return Movie(
            id: id,
            title: "Test Movie",
            overview: "This is a test movie.",
            posterPath: "/test.jpg",
            releaseDate: "2025-06-01",
            voteAverage: 8.0
        )
    }
    
    func sampleBookmark(id: Int = 1, timestamp: Date = Date()) -> Bookmark {
        return Bookmark(
            id: id,
            title: "Test Bookmark",
            overview: "This is a test bookmark.",
            posterPath: "/test.jpg",
            releaseDate: "2025-06-01",
            voteAverage: 8.0,
            timestamp: timestamp
        )
    }
}
