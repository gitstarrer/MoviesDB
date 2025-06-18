//
//  Endpoint.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//


import Foundation

enum Endpoint {
    case trendingMovies(page: Int)
    case nowPlayingMovies(page: Int)
    case searchMovies(query: String, page: Int)
    case popularMovies(page: Int) // New case
    
    var path: String {
        switch self {
        case .trendingMovies:
            return "/trending/movie/day"
        case .nowPlayingMovies:
            return "/movie/now_playing"
        case .searchMovies:
            return "/search/movie"
        case .popularMovies:
            return "/movie/popular"
        }
    }
    
    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "language", value: "en-US")]
        switch self {
        case .trendingMovies(let page), .nowPlayingMovies(let page), .popularMovies(let page):
            items.append(URLQueryItem(name: "page", value: "\(page)"))
        case .searchMovies(let query, let page):
            items.append(URLQueryItem(name: "query", value: query))
            items.append(URLQueryItem(name: "page", value: "\(page)"))
        }
        return items
    }
    
    func url(baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems
        return components?.url
    }
}
