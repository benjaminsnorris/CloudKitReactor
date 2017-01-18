//
//  FetchFromCloudKit.swift
//  Carrier
//
//  Created by Ben Norris on 1/18/17.
//  Copyright © 2017 BSN Design. All rights reserved.
//

import Foundation
import Reactor
import CloudKit

struct FetchFromCloudKit<T: CloudKitSyncable>: Command {
    
    var predicate: NSPredicate
    var privateDatabase: Bool
    
    init(predicate: NSPredicate = NSPredicate(value: true), privateDatabase: Bool = true) {
        self.predicate = predicate
        self.privateDatabase = privateDatabase
    }
    
    func execute(state: State, core: Core<State>) {
        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        let operation = CKQueryOperation(query: query)

        let perRecordBlock = { (fetchedRecord: CKRecord) -> Void in
            do {
                var object = try T(record: fetchedRecord)
                object.modifiedDate = Date()
                core.fire(event: Updated(object))
            } catch {
                core.fire(event: CloudKitRecordError<T>(error, for: fetchedRecord))
            }
        }
        operation.recordFetchedBlock = perRecordBlock
        
        var queryCompletionBlock: (CKQueryCursor?, Error?) -> Void = { (_, _) in }

        queryCompletionBlock = { queryCursor, error in
            if let queryCursor = queryCursor {
                let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                continuedQueryOperation.recordFetchedBlock = perRecordBlock
                continuedQueryOperation.queryCompletionBlock = queryCompletionBlock
                
                if self.privateDatabase {
                    CKContainer.default().privateCloudDatabase.add(continuedQueryOperation)
                } else {
                    CKContainer.default().publicCloudDatabase.add(continuedQueryOperation)
                }
                
            } else if let error = error {
                core.fire(event: CloudKitOperationUpdated<T>(status: .errored(error), type: .fetch))
            } else {
                core.fire(event: CloudKitOperationUpdated<T>(status: .completed, type: .fetch))
            }
        }
        operation.queryCompletionBlock = queryCompletionBlock
        
        if privateDatabase {
            CKContainer.default().privateCloudDatabase.add(operation)
        } else {
            CKContainer.default().publicCloudDatabase.add(operation)
        }

    }
    
}
