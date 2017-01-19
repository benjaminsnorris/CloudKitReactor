/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct FetchFromCloudKit<T: CloudKitSyncable, U: State>: Command {
    
    public var predicate: NSPredicate
    public var privateDatabase: Bool
    
    public init(predicate: NSPredicate = NSPredicate(value: true), privateDatabase: Bool = true) {
        self.predicate = predicate
        self.privateDatabase = privateDatabase
    }
    
    public func execute(state: U, core: Core<U>) {
        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        let operation = CKQueryOperation(query: query)
        var fetchedObjects = [T]()

        let perRecordBlock = { (fetchedRecord: CKRecord) -> Void in
            do {
                var object = try T(record: fetchedRecord)
                object.modifiedDate = Date()
                core.fire(event: Updated(object))
                fetchedObjects.append(object)
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
                core.fire(event: CloudKitOperationUpdated<T>(status: .completed(fetchedObjects), type: .fetch))
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
