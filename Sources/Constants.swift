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

    public static let zoneID = CKRecordZoneID(zoneName: defaultCustomZoneName, ownerName: CKCurrentUserDefaultName)
    
}
