//
//  Bookmark.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//


import Foundation

struct Bookmark: Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let timestamp: Date
}
