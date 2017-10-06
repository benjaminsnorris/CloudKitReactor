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
    public var databaseScope: CKDatabaseScope
    public var zoneID: CKRecordZoneID
    public var completion: ((Int) -> Void)?
    
    public init(predicate: NSPredicate = NSPredicate(value: true), databaseScope: CKDatabaseScope = .private, zoneID: CKRecordZoneID = CloudKitReactorConstants.zoneID, completion: ((Int) -> Void)? = nil) {
        self.predicate = predicate
        self.databaseScope = databaseScope
        self.zoneID = zoneID
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.zoneID = zoneID
        var fetchedObjects = [T]()

        let perRecordBlock = { (fetchedRecord: CKRecord) -> Void in
            do {
                var object = try T(record: fetchedRecord)
                object.modifiedDate = Date()
                core.fire(event: CloudKitUpdated(object))
                fetchedObjects.append(object)
            } catch {
                core.fire(event: CloudKitRecordError(error, for: fetchedRecord))
            }
        }
        operation.recordFetchedBlock = perRecordBlock
        
        var queryCompletionBlock: (CKQueryCursor?, Error?) -> Void = { (_, _) in }

        queryCompletionBlock = { queryCursor, error in
            if let queryCursor = queryCursor {
                let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                continuedQueryOperation.recordFetchedBlock = perRecordBlock
                continuedQueryOperation.queryCompletionBlock = queryCompletionBlock
                
                let container = CKContainer.default()
                switch self.databaseScope {
                case .private:
                    container.privateCloudDatabase.add(continuedQueryOperation)
                case .shared:
                    container.sharedCloudDatabase.add(continuedQueryOperation)
                case .public:
                    container.publicCloudDatabase.add(continuedQueryOperation)
                }
                
            } else if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .fetch))
            } else {
                core.fire(event: CloudKitOperationUpdated(status: .completed, type: .fetch))
            }
            self.completion?(fetchedObjects.count)
        }
        operation.queryCompletionBlock = queryCompletionBlock
        
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
