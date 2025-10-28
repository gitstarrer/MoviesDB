#  MoviesDB

## Overview

Movies App is an iOS application that allows users to explore trending and now-playing movies using the TMDB API. Users can search for movies, bookmark their favorites, and view movie details. The app supports offline functionality, pagination, and image caching, providing a seamless user experience.

## Features Implemented

### Core Features

1. Home Tab:
Displays Trending Movies and Now Playing Movies fetched from the TMDB API.
Supports pagination for "Now Playing" movies, loading more as the user scrolls.
Smooth scrolling with GeometryReader to handle pagination triggers.


2. Movie Details View:
Navigates to a detailed view when a user taps on a movie.
Displays movie title, overview, poster, release date, and rating.


3. Bookmarking:
Users can bookmark movies from the Home or Search tabs.
A dedicated Bookmarks Tab shows all bookmarked movies.
Bookmark state is reflected across the app with filled/unfilled icons.


4. Offline Support:
Uses Core Data to cache movie data locally.
Movies in the Home tab ("Trending" and "Now Playing") are cached and available offline.
Bookmarks are stored in Core Data and accessible offline.


5. Search Tab:
Users can search for movies using the TMDB API’s search endpoint.
Results are displayed in a grid, with navigation to the Movie Details view.


### Bonus Features

-> Debounced Search:
In the Search tab, network calls are made after the user stops typing (debounced with a 0.5-second delay).
Results update dynamically as the user types.


-> Image Caching:
Custom image caching using NSCache via ImagePrefetcher and CachedImageView.
Images are cached in memory and loaded asynchronously with URLSession.


-> ViewModels for UI State:
Uses MVVM architecture with NowPlayingMoviesViewModel, SearchViewModel, and BookmarksViewModel to manage UI state.
ViewModels handle data fetching, caching, and state updates (e.g., isLoading, error).


-> Cache Expiry:
Implements cache expiry for movies in the Home tab.
Cached movies are considered valid for 24 hours, after which the app fetches fresh data if online.



## Architecture

The app uses the MVVM (Model-View-ViewModel) architecture to separate concerns and improve testability:

Models: Movie and Bookmark structs represent the data.
Views: SwiftUI views (HomeView, SearchView, BookmarksView, MovieDetailView, MovieCardView) handle the UI.
ViewModels: NowPlayingMoviesViewModel, SearchViewModel, BookmarksViewModel and others, manage data fetching, state, and business logic.

Networking: APIService uses URLSession for API calls and Codable for JSON parsing.

Persistence: CoreDataManager handles Core Data operations for caching movies and bookmarks.

Dependency Injection: CoreDataManagerProtocol is used to inject the persistence layer, making the app more testable.

Key Components

APIService: Handles TMDB API requests with URLSession. Includes error handling and network timeout support.
CoreDataManager: Manages Core Data operations, including saving and fetching movies and bookmarks.
ImagePrefetcher: Implements image caching using NSCache to improve performance.
CachedImageView: A SwiftUI view that loads and displays cached images asynchronously.



##Steps to Run the App

### Prerequisites

1. Xcode: Version 16 or later.

2. iOS: iOS 16.0 or later (tested on iPhone 15 simulator).

3. TMDB API Key: 
Sign up at https://www.themoviedb.org/ and obtain an API key.
Open the project in Xcode.
Navigate to APIConfiguration.swift and replace the placeholder API key:
    static let bearerToken = "YOUR_API_KEY_HERE"// Replace with your TMDB API key



## Setup and Run

1. Unzip the Project:
Extract the MoviesApp.zip file to a folder on your Mac.

2. Open in Xcode:
Open MoviesApp.xcodeproj in Xcode.

3. Set the API Key:
Ensure you’ve added your TMDB API key in APIService.swift as described above.

4. Build and Run:
Select a simulator (e.g., iPhone 15) or a physical device.
Press Cmd+R to build and run the app.


## Explore the App:
Home Tab: View trending and now-playing movies. Scroll to load more movies in the "Now Playing" section.
Search Tab: Type a movie name to search. Results update as you type.
Bookmarks Tab: Bookmark movies from Home or Search tabs and view them here.
Offline Mode: Disconnect from the internet to test offline support for Home and Bookmarks tabs.


## Troubleshooting
API Key Issues:
If movies don’t load, verify your TMDB API key is correct and your internet connection is active.

Core Data Errors:
Ensure the MoviesApp.xcdatamodeld file is included in the project and target.

Simulator Issues:
If the app doesn’t run, clean the build folder (Cmd+Shift+K) and try again.


## Known Issues
Search Offline Support: Search tab requires an internet connection. Only the default screen is cached.
Sharing: Deep linking and sharing functionality is missing.
UI Polish: Lacks advanced animations and enhanced error handling UI due to time constraints.
