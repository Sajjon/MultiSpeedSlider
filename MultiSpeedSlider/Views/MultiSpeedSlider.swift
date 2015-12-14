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
    
    private let thumbTouchSize: CGSize = CGSizeMake(50, 50)
    
    private var beganTrackingLocation: CGPoint!
    private var realPositionValue: Float!
    
    public weak var delegate: MultiSpeedSliderProtocol?
    var scrubbingSpeeds: [Float] = [1.0, 0.5, 0.25, 0.1, 0.01, 0.001]
    var scrubbingSpeedChangePositions: [CGFloat] = [0.0, 50, 100, 150, 200, 250]
    var scrubbingSpeed: Float = 1.0 {
        didSet {
            if scrubbingSpeed != oldValue {
                delegate?.changedSpeed(scrubbingSpeed)
            }
        }
    }
        
    //MARK: - Private Methods
    private func beginTrackWithTouchUsingExtendedTouchArea(touch: UITouch) -> Bool {
        let thumbPercent = (value - minimumValue) / (maximumValue - minimumValue)
        
        let thumbHeight: CGFloat
        if let thumbImage = thumbImageForState(UIControlState.Normal) {
            thumbHeight = thumbImage.size.height
        } else {
            thumbHeight = self.frame.height
        }
        let thumbPos = CGFloat(thumbHeight) + (CGFloat(thumbPercent) * (CGFloat(bounds.size.width) - (2 * CGFloat(thumbHeight))))
        let touchPoint = touch.locationInView(self)
        
        let beginTouch = touchPoint.x >= (thumbPos - thumbTouchSize.width) && touchPoint.x <= (thumbPos + thumbTouchSize.width)
        return beginTouch
    }
    
    private func indexOfLowerScrubbingSpeed(scrubbingSpeedChangePositions maybeScrubbingSpeedChangePositions: [CGFloat]? = nil, forOffset verticalOffset: CGFloat) -> Int? {
        var index: Int? = nil
        
        let scrubbingSpeedChangePositions = maybeScrubbingSpeedChangePositions ?? self.scrubbingSpeedChangePositions
        for (scrubbingSpeedIndex, scrubbingSpeedVerticalOffset) in scrubbingSpeedChangePositions.enumerate() {
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
        let trackRect = trackRectForBounds(bounds)
        let thumbRect = thumbRectForBounds(bounds, trackRect: trackRect, value: value)
        let x = thumbRect.origin.x + (thumbRect.size.width/2)
        let y = thumbRect.origin.y + (thumbRect.size.height/2)
        beganTrackingLocation = CGPointMake(x, y)
        realPositionValue = value
    }
    
    //MARK: - Touch Events
    public override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let bounds = CGRectInset(self.bounds, -thumbTouchSize.width, -thumbTouchSize.height)
        return CGRectContainsPoint(bounds, point)
    }
    
    public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let beginTracking = beginTrackWithTouchUsingExtendedTouchArea(touch)
        
        if beginTracking {
            beganTracking()
            delegate?.scrubbingStatusChanged(true)
        }
        
        return beginTracking
    }
    
    public override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        if tracking {
            let previousLocation = touch.previousLocationInView(self)
            let currentLocation = touch.locationInView(self)
            let trackingOffsetX = currentLocation.x - previousLocation.x
            
            /* Find the scrubbing speed that corresponds to the touch's vertical offset */
            let verticalOffset = fabs(currentLocation.y - beganTrackingLocation.y)
            let scrubbingSpeedChangePositionIndex = indexOfLowerScrubbingSpeed(forOffset: verticalOffset) ?? scrubbingSpeeds.count
            scrubbingSpeed = scrubbingSpeeds[scrubbingSpeedChangePositionIndex - 1]
            
            let trackRect = trackRectForBounds(bounds)
            let valueInterval = maximumValue - minimumValue
            let trackingOffsetRelativeToTrackRect = Float(trackingOffsetX/trackRect.size.width)
            realPositionValue = realPositionValue + valueInterval * trackingOffsetRelativeToTrackRect
            let valueAdjustment = Float(scrubbingSpeed) * valueInterval * trackingOffsetRelativeToTrackRect
            var thumbAdjustment: Float = 0
            
            let aboveStartBelowPrevious = (beganTrackingLocation.y < currentLocation.y) && (currentLocation.y < previousLocation.y)
            let belowStartAbovePrevious = (beganTrackingLocation.y > currentLocation.y) && (currentLocation.y > previousLocation.y)
            if  aboveStartBelowPrevious || belowStartAbovePrevious {
                /* We are getting closer to the slider, go closer to the real location */
                thumbAdjustment = (realPositionValue - value) / Float(1 + fabs(currentLocation.y - beganTrackingLocation.y))
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
            
            if continuous {
                sendActionsForControlEvents(UIControlEvents.ValueChanged)
            }
        }
        
        return tracking
    }
    
    public override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        if tracking {
            scrubbingSpeed = scrubbingSpeeds[0]
            sendActionsForControlEvents(UIControlEvents.ValueChanged)
            delegate?.scrubbingStatusChanged(false)
        }
    }
}