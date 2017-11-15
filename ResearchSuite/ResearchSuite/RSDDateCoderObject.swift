//
//  RSDDateCoderObject.swift
//  ResearchSuite
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

/**
 `RSDDateCoderObject` provides a concrete implementation of a date coder.
 */
public struct RSDDateCoderObject : RSDDateCoder {
    
    public let resultFormatter: DateFormatter
    public let inputFormatter: DateFormatter
    public let calendarComponents: Set<Calendar.Component>
    public let calendar: Calendar
    
    public init() {
        let (inputFormatter, resultFormatter, components, calendar) = RSDDateCoderObject.getProperties(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")!
        self.resultFormatter = resultFormatter
        self.inputFormatter = inputFormatter
        self.calendarComponents = components
        self.calendar = calendar
    }
    
    public init?(format: String) {
        guard let (inputFormatter, resultFormatter, components, calendar) = RSDDateCoderObject.getProperties(format: format)
            else {
                return nil
        }
        self.resultFormatter = resultFormatter
        self.inputFormatter = inputFormatter
        self.calendarComponents = components
        self.calendar = calendar
    }
    
    public init(resultFormatter: DateFormatter, inputFormatter: DateFormatter, calendarComponents: Set<Calendar.Component>, calendar: Calendar) {
        self.resultFormatter = resultFormatter
        self.inputFormatter = inputFormatter
        self.calendarComponents = calendarComponents
        self.calendar = calendar
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let format = try container.decode(String.self)
        guard let (inputFormatter, resultFormatter, components, calendar) = RSDDateCoderObject.getProperties(format: format)
            else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Failed to get the calendar components from the decoded format \(format)"))
        }
        self.resultFormatter = resultFormatter
        self.inputFormatter = inputFormatter
        self.calendarComponents = components
        self.calendar = calendar
    }
    
    fileprivate static func getProperties(format: String) -> (inputFormatter: DateFormatter, resultFormatter: DateFormatter, Set<Calendar.Component>, Calendar)? {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.calendarComponents(from: format)
        guard components.count > 0 else {
            return nil
        }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = format
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let resultFormatter: DateFormatter
        let hasDateComponents = components.intersection([.year, .month, .day]).count > 0
        let hasTimeComponents = components.intersection([.hour, .minute, .second]).count > 0
        if hasDateComponents && hasTimeComponents {
            resultFormatter = RSDClassTypeMap.shared.timestampFormatter
        } else if hasTimeComponents {
            resultFormatter = RSDClassTypeMap.shared.timeOnlyFormatter
        } else {
            resultFormatter = RSDClassTypeMap.shared.dateOnlyFormatter
        }
        
        return (inputFormatter, resultFormatter, components, calendar)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.inputFormatter.dateFormat)
    }
}

extension Calendar {
    public func calendarComponents(from format: String) -> Set<Calendar.Component> {
        var components: Set<Calendar.Component> = []
        if format.range(of: "yyyy") != nil {
            components.insert(.year)
        }
        if format.range(of: "MM") != nil {
            components.insert(.month)
        }
        if format.range(of: "dd") != nil {
            components.insert(.day)
        }
        if format.range(of: "HH") != nil {
            components.insert(.hour)
        }
        if format.range(of: "mm") != nil {
            components.insert(.minute)
        }
        if format.range(of: "ss") != nil {
            components.insert(.second)
        }
        if format.range(of: "ss.SSS") != nil {
            components.insert(.nanosecond)
        }
        return components
    }
}
