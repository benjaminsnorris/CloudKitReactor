//
//  SaveToCloudKit.swift
//  Carrier
//
//  Created by Ben Norris on 1/16/17.
//  Copyright © 2017 BSN Design. All rights reserved.
//

import Foundation
import Reactor
import CloudKit

struct SaveToCloudKit<T: CloudKitSyncable>: Command {
    
    var objects: [T]
    var privateDatabase: Bool

    init(objects: [T], privateDatabase: Bool = true) {
        self.objects = objects
        self.privateDatabase = privateDatabase
    }
    
    func execute(state: State, core: Core<State>) {
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

protocol CloudKitErrorEvent: Reactor.Event {
    var error: Error { get }
}
protocol CloudKitDataEvent: Reactor.Event { }

struct CloudKitRecordError<T: CloudKitSyncable>: CloudKitErrorEvent {
    var error: Error
    var record: CKRecord
    
    init(_ error: Error, for record: CKRecord) {
        self.error = error
        self.record = record
    }
}

enum OperationType {
    case save
    case fetch
}

enum OperationStatus {
    case started
    case completed
    case errored(Error)
}

struct CloudKitOperationUpdated<T: CloudKitSyncable>: CloudKitDataEvent {
    var status: OperationStatus
    var type: OperationType
}
