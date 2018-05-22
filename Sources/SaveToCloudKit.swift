/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct SaveToCloudKit<T: CloudKitSyncable, U: State>: Command {
    
    public var objects: [T]
    public var savePolicy: CKRecordSavePolicy
    public var databaseScope: CKDatabaseScope
    public var completion: (() -> Void)?

    public init(_ objects: [T], savePolicy: CKRecordSavePolicy = .changedKeys, databaseScope: CKDatabaseScope = .private, completion: (() -> Void)? = nil) {
        self.objects = objects
        self.savePolicy = savePolicy
        self.databaseScope = databaseScope
        self.completion = completion
    }
    
    public init(_ object: T, savePolicy: CKRecordSavePolicy = .changedKeys, databaseScope: CKDatabaseScope = .private, completion: (() -> Void)? = nil) {
        self.init([object], savePolicy: savePolicy, databaseScope: databaseScope, completion: completion)
    }
    
    public func execute(state: U, core: Core<U>) {
        let records = objects.map { CKRecord(object: $0) }
        guard !records.isEmpty else { completion?(); return }
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = savePolicy
        operation.queuePriority = .high
        operation.qualityOfService = .userInteractive
        operation.isLongLived = true
        operation.perRecordCompletionBlock = { record, error in
            if let error = error {
                core.fire(event: CloudKitRecordError(error, for: record))
            } else {
                do {
                    let object = try T(record: record)
                    core.fire(event: CloudKitUpdated(object))
                } catch {
                    core.fire(event: CloudKitRecordError(error, for: record))
                }
            }
        }
        
        operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .save))
            } else {
                core.fire(event: CloudKitOperationUpdated(status: .completed, type: .save))
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
