//
//  MultiSpeedSlider.swift
//  MultiSpeedSlider
//
//  Created by Cyon Alexander on 07/12/15.
//  Copyright © 2015 Alexander Cyon. All rights reserved.
//

import UIKit

public protocol MultiSpeedSliderProtocol: class {
    func changedSpeed(newSpeed: Float)
    func scrubbingStatusChanged(nowScrubbing: Bool)
}

public class MultiSpeedSlider: UISlider {
    
    //MARK: - Private Variables
    private var beganTrackingLocation: CGPoint!
    private var realPositionValue: Float!

    //MARK: - Public Variables
    public weak var delegate: MultiSpeedSliderProtocol?
    public var thumbTouchSize: CGSize = CGSize(width: 50, height: 50)
    public var allowTap = false
    public var scrubbingSpeeds: [Float] = [1.0, 0.5, 0.25, 0.1, 0.01, 0.001]
    public var scrubbingSpeedChangePositions: [CGFloat] = [0.0, 50, 100, 150, 200, 250]
    public var scrubbingSpeed: Float = 1.0 {
        didSet {
            if scrubbingSpeed != oldValue {
                delegate?.changedSpeed(newSpeed: scrubbingSpeed)
            }
        }
    }
        
    //MARK: - Private Methods
    private func beginTrackWithTouchUsingExtendedTouchArea(touch: UITouch) -> Bool {
        let thumbPercent = (value - minimumValue) / (maximumValue - minimumValue)
        
        let thumbHeight: CGFloat
        if let thumbImage = thumbImage(for: UIControl.State.normal) {
            thumbHeight = thumbImage.size.height
        } else {
            thumbHeight = self.frame.height
        }
        let thumbPos = CGFloat(thumbHeight) + (CGFloat(thumbPercent) * (CGFloat(bounds.size.width) - (2 * CGFloat(thumbHeight))))
        let touchPoint = touch.location(in: self)
        
        let beginTouch = touchPoint.x >= (thumbPos - thumbTouchSize.width) && touchPoint.x <= (thumbPos + thumbTouchSize.width)
        return beginTouch
    }
    
    private func indexOfLowerScrubbingSpeed(scrubbingSpeedChangePositions maybeScrubbingSpeedChangePositions: [CGFloat]? = nil, forOffset verticalOffset: CGFloat) -> Int? {
        var index: Int? = nil
        
        let scrubbingSpeedChangePositions = maybeScrubbingSpeedChangePositions ?? self.scrubbingSpeedChangePositions
        for (scrubbingSpeedIndex, scrubbingSpeedVerticalOffset) in scrubbingSpeedChangePositions.enumerated() {
            if verticalOffset < scrubbingSpeedVerticalOffset {
                index = scrubbingSpeedIndex
                break
            }
        }
        return index
    }
    
    private func beganTracking() {
        /**
         * Set the beginning tracking location to the centre of the current position of the thumb.
         * This ensures that the thumb is correctly re-positioned when the touch position moves
         * back to the track after tracking in one of the slower tracking zones.
         */
        let trackRect1 = trackRect(forBounds: bounds)
        let thumbRect1 = thumbRect(forBounds: bounds, trackRect: trackRect1, value: value)
        let x = thumbRect1.origin.x + (thumbRect1.size.width/2)
        let y = thumbRect1.origin.y + (thumbRect1.size.height/2)
        beganTrackingLocation = CGPoint(x: x, y: y)
        realPositionValue = value
    }
    
    //MARK: - Touch Events
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let bounds = self.bounds.insetBy(dx: -thumbTouchSize.width, dy: -thumbTouchSize.height)
        return bounds.contains(point)
    }
    
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let beginTracking = beginTrackWithTouchUsingExtendedTouchArea(touch: touch) || allowTap

        if allowTap {
            let tapPoint = touch.location(in: self)
            let valueFromTap = CGFloat(maximumValue - minimumValue) * (tapPoint.x - CGFloat(thumbTouchSize.width/2)) / (frame.size.width - thumbTouchSize.width)
            let newValue = minimumValue + Float(valueFromTap)
            setValue(newValue, animated: true)
            sendActions(for: .touchDragInside)
            sendActions(for: .valueChanged)
        }

        if beginTracking {
            beganTracking()
            delegate?.scrubbingStatusChanged(nowScrubbing: true)
        }

        return beginTracking
    }
    
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if isTracking {
            let previousLocation = touch.previousLocation(in: self)
            let currentLocation = touch.location(in: self)
            let trackingOffsetX = currentLocation.x - previousLocation.x
            
            /* Find the scrubbing speed that corresponds to the touch's vertical offset */
            let verticalOffset = abs(currentLocation.y - beganTrackingLocation.y)
            let scrubbingSpeedChangePositionIndex = indexOfLowerScrubbingSpeed(forOffset: verticalOffset) ?? scrubbingSpeeds.count
            scrubbingSpeed = scrubbingSpeeds[scrubbingSpeedChangePositionIndex - 1]
            
            let trackRect1 = trackRect(forBounds: bounds)
            let valueInterval = maximumValue - minimumValue
            let trackingOffsetRelativeToTrackRect = Float(trackingOffsetX/trackRect1.size.width)
            realPositionValue = realPositionValue + valueInterval * trackingOffsetRelativeToTrackRect
            let valueAdjustment = Float(scrubbingSpeed) * valueInterval * trackingOffsetRelativeToTrackRect
            var thumbAdjustment: Float = 0
            
            let aboveStartBelowPrevious = (beganTrackingLocation.y < currentLocation.y) && (currentLocation.y < previousLocation.y)
            let belowStartAbovePrevious = (beganTrackingLocation.y > currentLocation.y) && (currentLocation.y > previousLocation.y)
            if  aboveStartBelowPrevious || belowStartAbovePrevious {
                /* We are getting closer to the slider, go closer to the real location */
                thumbAdjustment = (realPositionValue - value) / Float(1 + abs(currentLocation.y - beganTrackingLocation.y))
            }
            
            let totalAdjustment = valueAdjustment + thumbAdjustment
            var changeValue = false
            
            /* Prevent value from increasing if we scrubbed left (only allow decreasing) */
            let scrubbingLeft = currentLocation.x < previousLocation.x
            if totalAdjustment < 0 && scrubbingLeft {
                changeValue = true
            }
            
            /* Prevent value from decreasing if we scrubbed right (only allow increasing) */
            let scrubbingRight = currentLocation.x > previousLocation.x
            if totalAdjustment > 0 && scrubbingRight {
                changeValue = true
            }
            
            /* Prevent "bad" values, maybe this can be prevented in a smarter way? */
            if changeValue {
                value += totalAdjustment
            }
            
            if isContinuous {
                sendActions(for: UIControl.Event.valueChanged)
            }
        }
        
        return isTracking
    }
    
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if isTracking {
            scrubbingSpeed = scrubbingSpeeds[0]
            sendActions(for: UIControl.Event.valueChanged)
            delegate?.scrubbingStatusChanged(nowScrubbing: false)
        }
    }
}
