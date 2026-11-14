import Foundation
import SwiftData

/// One logged night. Stored on-device with SwiftData.
@Model
final class NightLog {
    var date: Date
    /// 1 (calm) to 5 (very itchy).
    var itch: Int
    var tags: [String]
    var zoneIDs: [String]
    var ritualMinutes: Int
    var storyID: String

    init(date: Date = .now, itch: Int, tags: [String], zoneIDs: [String], ritualMinutes: Int, storyID: String) {
        self.date = date
        self.itch = itch
        self.tags = tags
        self.zoneIDs = zoneIDs
        self.ritualMinutes = ritualMinutes
        self.storyID = storyID
    }
}

enum NightTags {
    static let all = ["Scratched in sleep", "Fell asleep fast", "New product", "Hot or dry day", "Swimming or bath", "Woke up itchy"]
}
