//
//  CoreDataManager.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//

import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let persistentContainer: NSPersistentContainer
    
    init() {
        persistentContainer = NSPersistentContainer(name: "MoviesApp")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func backgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func saveMovies(_ movies: [Movie], category: String, in context: NSManagedObjectContext) {
        context.performAndWait {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = MovieEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "category == %@", category)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try? context.execute(deleteRequest)
            
            for movie in movies {
                let movieEntity = MovieEntity(context: context)
                movieEntity.id = Int64(movie.id)
                movieEntity.title = movie.title
                movieEntity.overview = movie.overview
                movieEntity.posterPath = movie.posterPath
                movieEntity.releaseDate = movie.releaseDate
                movieEntity.voteAverage = movie.voteAverage ?? 0
                movieEntity.lastUpdated = Date()
                movieEntity.category = category
            }
            saveContext(context)
        }
    }
    
    func fetchMovies(category: String, in context: NSManagedObjectContext) -> [Movie] {
        let fetchRequest: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { entity in
                Movie(
                    id: Int(entity.id),
                    title: entity.title ?? "",
                    overview: entity.overview ?? "",
                    posterPath: entity.posterPath,
                    releaseDate: entity.releaseDate,
                    voteAverage: entity.voteAverage
                )
            }
        } catch {
            print("Failed to fetch movies: \(error)")
            return []
        }
    }
    
    func isCacheValid(category: String, in context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        
        do {
            if let entity = try context.fetch(fetchRequest).first,
               let lastUpdated = entity.lastUpdated {
                let cacheAge = Date().timeIntervalSince(lastUpdated)
                return cacheAge < 24 * 60 * 60 // 24 hours
            }
            return false
        } catch {
            return false
        }
    }
    
    func saveBookmark(_ bookmark: Bookmark, in context: NSManagedObjectContext) {
        context.perform {
            let bookmarkEntity = NSEntityDescription.insertNewObject(forEntityName: "BookmarkEntity", into: context)
            bookmarkEntity.setValue(bookmark.id, forKey: "id")
            bookmarkEntity.setValue(bookmark.title, forKey: "title")
            bookmarkEntity.setValue(bookmark.overview, forKey: "overview")
            bookmarkEntity.setValue(bookmark.posterPath, forKey: "posterPath")
            bookmarkEntity.setValue(bookmark.releaseDate, forKey: "releaseDate")
            bookmarkEntity.setValue(bookmark.voteAverage, forKey: "voteAverage")
            bookmarkEntity.setValue(bookmark.timestamp, forKey: "timestamp")
            
            do {
                try context.save()
            } catch {
                print("Failed to save bookmark: \(error)")
            }
        }
    }
    
    func fetchBookmarks(in context: NSManagedObjectContext) -> [Bookmark] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BookmarkEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let bookmarkEntities = try context.fetch(fetchRequest)
            return bookmarkEntities.map { entity in
                Bookmark(
                    id: entity.value(forKey: "id") as! Int,
                    title: entity.value(forKey: "title") as! String,
                    overview: entity.value(forKey: "overview") as! String,
                    posterPath: entity.value(forKey: "posterPath") as? String,
                    releaseDate: entity.value(forKey: "releaseDate") as? String,
                    voteAverage: entity.value(forKey: "voteAverage") as! Double,
                    timestamp: entity.value(forKey: "timestamp") as! Date
                )
            }
        } catch {
            print("Failed to fetch bookmarks: \(error)")
            return []
        }
    }
    
    func isBookmarked(movieId: Int, in context: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BookmarkEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %d", movieId)
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Failed to check if bookmarked: \(error)")
            return false
        }
    }
    
    func deleteBookmark(movieId: Int, in context: NSManagedObjectContext) {
        context.perform {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BookmarkEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %d", movieId)
            
            do {
                let bookmarks = try context.fetch(fetchRequest)
                for bookmark in bookmarks {
                    context.delete(bookmark)
                }
                try context.save()
            } catch {
                print("Failed to delete bookmark: \(error)")
            }
        }
    }
}
