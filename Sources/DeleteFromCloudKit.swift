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
    public var databaseScope: CKDatabaseScope
    
    public init(_ objects: [T], privateDatabase: CKDatabaseScope = .private) {
        self.objects = objects
        self.databaseScope = privateDatabase
    }
    
    public func execute(state: U, core: Core<U>) {
        let recordIDs = objects.flatMap { $0.cloudKitRecordID }
        guard !recordIDs.isEmpty else { return }
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.savePolicy = .ifServerRecordUnchanged
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .delete))
            } else {
                core.fire(event: CloudKitOperationUpdated(status: .completed, type: .delete))
            }
        }
        operation.qualityOfService = .userInitiated
        
        let container = CKContainer.default()
        switch databaseScope {
        case .private:
            container.privateCloudDatabase.add(operation)
        case .shared:
            container.sharedCloudDatabase.add(operation)
        case .public:
            container.publicCloudDatabase.add(operation)
        }

    }
    
}
