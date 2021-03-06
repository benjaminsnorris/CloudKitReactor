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
    public static let zoneID = CKRecordZone.ID(zoneName: defaultCustomZoneName, ownerName: CKCurrentUserDefaultName)
    
    public static let privateDatabaseSubscription = "privateDatabaseSubscription"
    public static let sharedDatabaseSubscription = "sharedDatabaseSubscription"
    
}
