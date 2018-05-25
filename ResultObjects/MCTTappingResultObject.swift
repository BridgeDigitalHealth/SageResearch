//
//  MCTTappingResultObject.swift
//  MotorControl
//
//  Copyright © 2015 Apple Inc.
//  Ported to Swift from ResearchKit/ResearchKit 1.5
//
//  Copyright © 2018 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

extension RSDResultType {
    
    /// The type identifier for a tapping result.
    public static let tapping: RSDResultType = "tapping"
}

/// The `MCTTappingResultObject` records the results of a tapping interval test.
///
/// The tapping interval result object records an array of touch samples (one for each tap) and also the
/// geometry of the task at the time it was displayed. You can use the information in the object for reference
/// in interpreting the touch samples.
///
/// A tapping interval sample is typically generated by the framework as the task proceeds. When the task
/// completes, it may be appropriate to serialize it for transmission to a server,
/// or to immediately perform analysis on it.
public struct MCTTappingResultObject : RSDResult, Encodable, RSDArchivable {
    
    private enum CodingKeys : String, CodingKey {
        case identifier, type, startDate, endDate, stepViewSize = "viewSize", buttonRect1 = "buttonRectLeft", buttonRect2 = "buttonRectRight", samples
    }

    /// The identifier for the associated step.
    public var identifier: String
    
    /// Default = `.tapping`.
    public private(set) var type: RSDResultType = .tapping
    
    /// Timestamp date for when the step was started.
    public var startDate: Date = Date()
    
    /// Timestamp date for when the step was ended.
    public var endDate: Date = Date()

    /// An array of collected tapping samples.
    public internal(set) var samples: [MCTTappingSample]? = nil

    /// The size of the bounds of the step view containing the tap targets.
    public internal(set) var stepViewSize: CGSize = .zero

    /// The frame of the left button, in points, relative to the step view bounds.
    public internal(set) var buttonRect1: CGRect = .zero

    /// The frame of the right button, in points, relative to the step view bounds.
    public internal(set) var buttonRect2: CGRect = .zero
    
    init(identifier: String) {
        self.identifier = identifier
    }
    
    /// Build the archiveable or uploadable data for this result.
    public func buildArchiveData(at stepPath: String?) throws -> (manifest: RSDFileManifest, data: Data)? {
        
        // The filename should include the section (left/right).
        let filename : String = {
            guard let pathComponent = stepPath?.components(separatedBy: "/").first(where: {
                MCTHandSelection(rawValue: $0) != nil
            }) else {
                return self.identifier
            }
            return "\(pathComponent)_\(self.identifier)"
        }()
        
        // create the manifest and encode the result.
        let manifest = RSDFileManifest(filename: filename, timestamp: self.startDate, contentType: "application/json", identifier: self.identifier, stepPath: stepPath)
        let data = try self.rsd_jsonEncodedData()
        return (manifest, data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.startDate, forKey: .startDate)
        try container.encode(self.endDate, forKey: .endDate)
        try container.encode(NSStringFromCGSize(self.stepViewSize) as String, forKey: .stepViewSize)
        try container.encode(NSStringFromCGRect(self.buttonRect1) as String, forKey: .buttonRect1)
        try container.encode(NSStringFromCGRect(self.buttonRect2) as String, forKey: .buttonRect2)
        if let samples = self.samples {
            try container.encode(samples, forKey: .samples)
        }
    }
}

/// Values that identify the button that was tapped in a tapping sample.
public enum MCTTappingButtonIdentifier : String, Codable {
    case none, left, right
}

/// The `MCTTappingSample` class represents a single tap on a button.
///
/// The tapping sample object records the location of the tap, the
/// button that was tapped, and the time at which the event occurred. A tapping sample is
/// included in an `MCTTappingResultObject` object, and is recorded by the
/// step view controller for the corresponding task when a tap is
/// recognized.
///
/// A tapping sample is typically generated by the framework as the task proceeds. When the task
/// completes, it may be appropriate to serialize the sample for transmission to a server,
/// or to immediately perform analysis on it.
public struct MCTTappingSample : RSDSampleRecord, Codable {
    
    /// Clock time for the sample.
    public let uptime: TimeInterval
    
    /// A relative timestamp indicating the time of the tap event.
    ///
    /// The timestamp is relative to the value of `startDate` in the `RSDResult` object that includes this
    /// sample.
    public let timestamp: TimeInterval?
    
    /// The current step path.
    public let stepPath: String

    /// An enumerated value that indicates which button was tapped, if any.
    ///
    /// If the value of this property is `.none`, it indicates that the tap was near, but not inside, one
    /// of the target buttons.
    public let buttonIdentifier: MCTTappingButtonIdentifier

    /// The location of the tap within the step's view.
    ///
    /// The location coordinates are relative to a rectangle whose size corresponds to
    /// the `stepViewSize` in the enclosing `MCTTappingResultObject` object.
    public let location: CGPoint
    
    /// A duration of the tap event.
    ///
    /// The duration store time interval between touch down and touch release events.
    public internal(set) var duration: TimeInterval
    
    /// Ignored.
    public var timestampDate: Date? {
        return nil
    }
}

