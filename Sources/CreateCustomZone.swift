/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit
import Reactor

let defaultCustomZoneName = "DefaultCustomZone"

public struct CreateCustomZone<U: State>: Command {
    
    public var zoneName: String
    
    public init(named zoneName: String) {
        self.zoneName = zoneName
    }
    
    public func execute(state: U, core: Core<U>) {
        let zoneID = CKRecordZoneID(zoneName: defaultCustomZoneName, ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        operation.modifyRecordZonesCompletionBlock = { saved, _, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .save))
            } else {
                core.fire(event: CloudKitOperationUpdated(status: .completed, type: .save))
                core.fire(event: CloudKitDefaultCustomZoneCreated(zoneID: zoneID))
            }
        }
        operation.qualityOfService = .userInitiated
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
}
