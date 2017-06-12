/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit
import Reactor


public struct CreateCustomZone<U: State>: Command {
    
    public var zoneName: String?
    
    public init(named zoneName: String? = nil) {
        self.zoneName = zoneName
    }
    
    public func execute(state: U, core: Core<U>) {
        let zoneID: CKRecordZoneID
        if let zoneName = zoneName {
            zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        } else {
            zoneID = CloudKitReactorConstants.zoneID
        }
        let zone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        operation.modifyRecordZonesCompletionBlock = { saved, _, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .save))
            } else {
                core.fire(event: CloudKitOperationUpdated(status: .completed, type: .save))
                core.fire(event: CloudKitDefaultCustomZoneCreated(zoneID: CloudKitReactorConstants.zoneID))
            }
        }
        operation.qualityOfService = .userInitiated
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
}
