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
    public var privateDatabase: Bool
    public var completion: (() -> Void)?

    public init(_ objects: [T], savePolicy: CKRecordSavePolicy = .changedKeys, privateDatabase: Bool = true, completion: (() -> Void)? = nil) {
        self.objects = objects
        self.savePolicy = savePolicy
        self.privateDatabase = privateDatabase
        self.completion = completion
    }
    
    public init(_ object: T, savePolicy: CKRecordSavePolicy = .changedKeys, privateDatabase: Bool = true, completion: (() -> Void)? = nil) {
        self.init([object], savePolicy: savePolicy, privateDatabase: privateDatabase, completion: completion)
    }
    
    public func execute(state: U, core: Core<U>) {
        let records = objects.map { CKRecord(object: $0) }
        guard !records.isEmpty else { return }
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = savePolicy
        operation.queuePriority = .high
        operation.qualityOfService = .userInteractive
        operation.perRecordCompletionBlock = { record, error in
            if let error = error {
                core.fire(event: CloudKitRecordError<T>(error, for: record))
            } else {
                do {
                    var object = try T(record: record)
                    object.modifiedDate = Date()
                    core.fire(event: CloudKitUpdated(object))
                } catch {
                    core.fire(event: CloudKitRecordError<T>(error, for: record))
                }
            }
        }
        
        operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
            if let error = error {
                core.fire(event: CloudKitOperationUpdated<T>(status: .errored(error), type: .save))
            } else {
                core.fire(event: CloudKitOperationUpdated<T>(status: .completed(self.objects), type: .save))
            }
            self.completion?()
        }
        
        if privateDatabase {
            CKContainer.default().privateCloudDatabase.add(operation)
        } else {
            CKContainer.default().publicCloudDatabase.add(operation)
        }
        
    }
    
}
