//
//  Debouncer.swift
//  MoviesDB_inShorts
//
//  Created by Himanshu Gupta on 10/06/25.
//


import Foundation

class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(_ action: @escaping () -> Void) {
        workItem?.cancel()
        let newWorkItem = DispatchWorkItem { action() }
        workItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
}