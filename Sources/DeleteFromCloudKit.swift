/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit
import Reactor

public struct DeleteFromCloudKit<U: State>: Command {
    
    public var objects: [CloudKitSyncable]
    public var records: [CKRecord]
    public var databaseScope: CKDatabaseScope
    let completion: (() -> Void)?
    
    public init(_ objects: [CloudKitSyncable] = [], records: [CKRecord] = [], databaseScope: CKDatabaseScope = .private, completion: (() -> Void)? = nil) {
        self.objects = objects
        self.records = records
        self.databaseScope = databaseScope
        self.completion = completion
    }
    
    public init(_ object: CloudKitSyncable? = nil, record: CKRecord? = nil, databaseScope: CKDatabaseScope = .private, completion: (() -> Void)? = nil) {
        if let object = object {
            self.init([object], databaseScope: databaseScope, completion: completion)
        } else if let record = record {
            self.init(records: [record], databaseScope: databaseScope, completion: completion)
        } else {
            self.init([], completion: completion)
        }
    }
    
    public func execute(state: U, core: Core<U>) {
        var recordIDs = objects.flatMap { $0.cloudKitRecordID }
        recordIDs += records.map { $0.recordID }
        guard !recordIDs.isEmpty else { completion?(); return }
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.savePolicy = .ifServerRecordUnchanged
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .delete))
            } else {
                core.fire(event: CloudKitOperationUpdated(status: .completed, type: .delete))
            }
            self.completion?()
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
