/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit
import Reactor

public struct DeleteFromCloudKit<T: CloudKitSyncable, U: State>: Command {
    
    public var objects: [T]
    public var privateDatabase: Bool
    
    public init(_ objects: [T], privateDatabase: Bool = true) {
        self.objects = objects
        self.privateDatabase = privateDatabase
    }
    
    public func execute(state: U, core: Core<U>) {
        let recordIDs = objects.flatMap { $0.cloudKitRecordID }
        guard !recordIDs.isEmpty else { return }
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.savePolicy = .ifServerRecordUnchanged
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated<T>(status: .errored(error), type: .delete))
            } else {
                core.fire(event: CloudKitOperationUpdated<T>(status: .completed(self.objects), type: .delete))
            }
        }
        
        if privateDatabase {
            CKContainer.default().privateCloudDatabase.add(operation)
        } else {
            CKContainer.default().publicCloudDatabase.add(operation)
        }

    }
    
}
