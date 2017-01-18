/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

struct SaveToCloudKit<T: CloudKitSyncable, U: State>: Command {
    
    var objects: [T]
    var privateDatabase: Bool

    init(objects: [T], privateDatabase: Bool = true) {
        self.objects = objects
        self.privateDatabase = privateDatabase
    }
    
    func execute(state: U, core: Core<U>) {
        let records = objects.map { CKRecord(object: $0) }
        guard !records.isEmpty else { return }
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.queuePriority = .high
        operation.qualityOfService = .userInteractive
        operation.perRecordCompletionBlock = { record, error in
            if let error = error {
                core.fire(event: CloudKitRecordError<T>(error, for: record))
            } else {
                do {
                    var object = try T(record: record)
                    object.modifiedDate = Date()
                    core.fire(event: Updated(object))
                } catch {
                    core.fire(event: CloudKitRecordError<T>(error, for: record))
                }
            }
        }
        
        operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated<T>(status: .errored(error), type: .save))
            } else {
                core.fire(event: CloudKitOperationUpdated<T>(status: .completed, type: .save))
            }
        }
        
        if privateDatabase {
            CKContainer.default().privateCloudDatabase.add(operation)
        } else {
            CKContainer.default().publicCloudDatabase.add(operation)
        }
        
    }
    
}
