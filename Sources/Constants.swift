/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit

public enum CloudKitReactorConstants {
    
    static let defaultCustomZoneName = "DefaultCustomZone"
    static let privateDatabaseSubscription = "privateDatabaseSubscription"
    static let sharedDatabaseSubscription = "sharedDatabaseSubscription"

    public static let zoneID = CKRecordZoneID(zoneName: defaultCustomZoneName, ownerName: CKCurrentUserDefaultName)
    
}
