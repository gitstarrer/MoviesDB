//
//  ImageCache.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//


import UIKit

class ImagePrefetcher {
    static let sharedCache = NSCache<NSURL, UIImage>()
    private let cache: NSCache<NSURL, UIImage>
    
    init() {
        self.cache = ImagePrefetcher.sharedCache
        cache.countLimit = 100 // Limit to 100 images in memory
    }
    
    func prefetchImages(for movies: [Movie], maxConcurrent: Int? = nil) async {
        let imageURLs = movies.compactMap { movie -> URL? in
            guard let posterPath = movie.posterPath else { return nil }
            return URL(string: "\(APIConfiguration.imageBaseURL)\(posterPath)")
        }
        
        await withTaskGroup(of: Void.self) { group in
            let concurrentLimit = maxConcurrent ?? 5
            var currentIndex = 0
            
            while currentIndex < min(concurrentLimit, imageURLs.count) {
                let url = imageURLs[currentIndex]
                group.addTask {
                    await self.downloadImage(from: url)
                }
                currentIndex += 1
            }
            
            for await _ in group {
                if currentIndex < imageURLs.count {
                    let url = imageURLs[currentIndex]
                    group.addTask {
                        await self.downloadImage(from: url)
                    }
                    currentIndex += 1
                }
            }
        }
    }
    
    private func downloadImage(from url: URL) async {
        if cache.object(forKey: url as NSURL) != nil {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                cache.setObject(image, forKey: url as NSURL)
            }
        } catch {
            print("Failed to prefetch image from \(url): \(error)")
        }
    }
}
