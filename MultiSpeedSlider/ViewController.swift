//
//  ViewController.swift
//  MultiSpeedSlider
//
//  Created by Cyon Alexander on 07/12/15.
//  Copyright © 2015 Alexander Cyon. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MultiSpeedSliderProtocol {

    //MARK: - IBOutlet Variables
    @IBOutlet weak var slider: MultiSpeedSlider!
    @IBOutlet weak var elapsed: UILabel!
    @IBOutlet weak var remaining: UILabel!
    @IBOutlet weak var speedValueLabel: UILabel!
    
    //MARK: - ViewController Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSlider()
        updateLabels()
    }
    
    //MARK: - Private Methods
    private func setupSlider() {
        slider.delegate = self
        slider.minimumValue = 0
        slider.value = slider.minimumValue
        slider.maximumValue = 36000 //10h long sound track
        slider.allowTap = true
    }
    
    private func durationAsHourMinuteSecondString(timeInterval: TimeInterval) -> String {
        let interval = Int(timeInterval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        let timeString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        return timeString
    }
    
    private func updateLabels(maybeTimeElapsed: TimeInterval? = nil) {
        let timeElapsed = maybeTimeElapsed ?? TimeInterval(slider.value)
        let timeRemaining = TimeInterval(slider.maximumValue) - timeElapsed
        elapsed.text = durationAsHourMinuteSecondString(timeInterval: timeElapsed)
        remaining.text = durationAsHourMinuteSecondString(timeInterval: timeRemaining)
    }
    
    //MARK: - MultiSpeedSliderProtocol Methods
    func changedSpeed(newSpeed: Float) {
        speedValueLabel.text = "\(newSpeed)"
    }
    
    func scrubbingStatusChanged(nowScrubbing: Bool) {
        print("nowScrubbing: \(nowScrubbing)")
    }
    
    //MARK: - IBAction Methods
    @IBAction func valueChanged(sender: UISlider) {
        let elapsedValue = TimeInterval(Int(round((sender.value*1)/1)))
        let remainingAsFloat = sender.maximumValue - sender.value
        let remainingValue = TimeInterval(Int(round((remainingAsFloat*1)/1)))
        elapsed.text = durationAsHourMinuteSecondString(timeInterval: elapsedValue)
        remaining.text = durationAsHourMinuteSecondString(timeInterval: remainingValue)
    }
}

