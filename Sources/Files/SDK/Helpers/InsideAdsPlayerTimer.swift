//
//  InsideAdsPlayerTimer.swift
//  TestTheLibrary
//
//  Created by Katerina Kolevska on 27.12.23.
//

import Foundation

class InsideAdsPlayerTimer: ObservableObject {
    @Published var showAd: Bool = false
    @Published var counter: Int = 0
    @Published var timer = Timer()
    @Published var insideAdsPlayerIntervalInMinutes: Int
    
    init(insideAdsPlayerIntervalInMinutes: Int) {
        self.insideAdsPlayerIntervalInMinutes = insideAdsPlayerIntervalInMinutes
    }
    
    func start() {
        self.timer.invalidate()
        self.counter = 0
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                                   repeats: true) { [weak self] _ in
            self?.counter += 1
            print("timerValue input \(self?.counter)")
            if self?.counter == self?.insideAdsPlayerIntervalInMinutes {
                self?.showAd.toggle()
                self?.reset()
                self?.start()
            }
        }
    }
    func stop() {
        self.timer.invalidate()
    }
    func reset() {
        self.counter = 0
        self.timer.invalidate()
    }
}
