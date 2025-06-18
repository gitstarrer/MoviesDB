//
//  MainTabView.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var bookmarkViewModel = BookmarksViewModel(coreDataManager: .shared)
    
    var body: some View {
            TabView {
                NavigationStack {
                    HomeView(bookmarkViewModel: bookmarkViewModel)
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                
                NavigationStack {
                    SearchView(bookmarksViewModel: bookmarkViewModel)
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                
                NavigationStack {
                    BookmarksView(viewModel: bookmarkViewModel)
                }
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }
            }
        }
}

#Preview {
    MainTabView()
}
