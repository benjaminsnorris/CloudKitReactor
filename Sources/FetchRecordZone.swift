/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct FetchRecordZone<U: State>: Command {
    
    public var zoneID: CKRecordZoneID
    public var completion: ((Bool) -> Void)?
    
    public init(with zoneID: CKRecordZoneID, completion: ((Bool) -> Void)? = nil) {
        self.zoneID = zoneID
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        let operation = CKFetchRecordZonesOperation(recordZoneIDs: [zoneID])
        operation.fetchRecordZonesCompletionBlock = { zonesDictionary, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .fetch))
                self.completion?(false)
            } else {
                let found = zonesDictionary?[self.zoneID] != nil
                core.fire(event: CloudKitOperationUpdated(status: .completed, type: .fetch))
                self.completion?(found)
            }
        }
        operation.qualityOfService = .userInitiated
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
}
