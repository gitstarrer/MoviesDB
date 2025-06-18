//
//  APIService.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 15/06/25.
//


import Foundation

protocol APIServiceProtocol {
    func fetchTrendingMovies(page: Int) async throws -> APIResponse<Movie>
    func fetchNowPlayingMovies(page: Int) async throws -> APIResponse<Movie>
    func searchMovies(query: String, page: Int) async throws -> APIResponse<Movie>
    func fetchPopularMovies(page: Int) async throws -> APIResponse<Movie> // New method
}

class APIService: APIServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private func performRequest<T: Decodable>(endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url(baseURL: APIConfiguration.baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(APIConfiguration.bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func fetchTrendingMovies(page: Int) async throws -> APIResponse<Movie> {
        try await performRequest(endpoint: .trendingMovies(page: page))
    }
    
    func fetchNowPlayingMovies(page: Int) async throws -> APIResponse<Movie> {
        try await performRequest(endpoint: .nowPlayingMovies(page: page))
    }
    
    func searchMovies(query: String, page: Int) async throws -> APIResponse<Movie> {
        try await performRequest(endpoint: .searchMovies(query: query, page: page))
    }
    
    func fetchPopularMovies(page: Int) async throws -> APIResponse<Movie> {
        try await performRequest(endpoint: .popularMovies(page: page))
    }
}
