/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct SaveCloudKitRecords<U: State>: Command {
    
    public var records: [CKRecord]
    public var objects: [CloudKitSyncable]
    public var savePolicy: CKRecordSavePolicy
    public var databaseScope: CKDatabaseScope
    public var completion: ((Error?) -> Void)?
    
    public init(_ records: [CKRecord] = [], objects: [CloudKitSyncable] = [], savePolicy: CKRecordSavePolicy = .ifServerRecordUnchanged, databaseScope: CKDatabaseScope = .private, completion: ((Error?) -> Void)? = nil) {
        self.records = records
        self.objects = objects
        self.savePolicy = savePolicy
        self.databaseScope = databaseScope
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        var records = self.records
        records += objects.map { CKRecord(object: $0) }
        guard !records.isEmpty else { return }
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = savePolicy
        operation.queuePriority = .high
        operation.qualityOfService = .userInteractive
        operation.isLongLived = true
        operation.perRecordCompletionBlock = { record, error in
            if let error = error {
                core.fire(event: CloudKitRecordError(error, for: record))
            } else {
                core.fire(event: CloudKitUpdated(record))
            }
        }
        
        operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .save))
            } else {
                core.fire(event: CloudKitOperationUpdated(status: .completed, type: .save))
            }
            self.completion?(error)
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
