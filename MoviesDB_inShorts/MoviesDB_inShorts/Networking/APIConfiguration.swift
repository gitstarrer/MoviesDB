//
//  APIConfiguration.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//


import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int)
}

struct APIConfiguration {
    static let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p/w500"
    static let bearerToken = "YOUR_API_KEY_HERE"
}
