/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct FetchChangesFromCloudKit<U: State>: Command {
    
    public let objectTypes: [CloudKitSyncable.Type]
    public var recordZoneIDs: [CKRecordZoneID]
    public var recordZoneChangesOptions: [CKFetchRecordZoneChangesOptions]
    public var defaultZoneChangeToken: CKServerChangeToken?
    public var privateDatabase: Bool
    public var completion: ((_ changes: Bool) -> Void)?
    
    fileprivate var defaultZoneOnly: Bool {
        return recordZoneIDs == [CloudKitReactorConstants.zoneID] && recordZoneChangesOptions.isEmpty
    }
    
    public init(with objectTypes: [CloudKitSyncable.Type], recordZoneIDs: [CKRecordZoneID] = [CloudKitReactorConstants.zoneID], recordZoneChangesOptions: [CKFetchRecordZoneChangesOptions] = [], defaultZoneChangeToken: CKServerChangeToken? = nil, privateDatabase: Bool = true, completion: ((_ changes: Bool) -> Void)? = nil) {
        self.objectTypes = objectTypes
        self.recordZoneIDs = recordZoneIDs
        self.recordZoneChangesOptions = recordZoneChangesOptions
        self.defaultZoneChangeToken = defaultZoneChangeToken
        self.privateDatabase = privateDatabase
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        let operation = CKFetchRecordZoneChangesOperation()
        operation.recordZoneIDs = recordZoneIDs
        if defaultZoneOnly {
            let options = CKFetchRecordZoneChangesOptions()
            options.previousServerChangeToken = defaultZoneChangeToken
            operation.optionsByRecordZoneID = [CKRecordZone.default().zoneID: options]
        } else {
            var allOptions = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
            for (index, zoneID) in recordZoneIDs.enumerated() {
                guard index < recordZoneChangesOptions.count else { break }
                allOptions[zoneID] = recordZoneChangesOptions[index]
            }
            operation.optionsByRecordZoneID = allOptions
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, serverToken, clientTokenData in
            core.fire(event: CloudKitServerChangeTokenUpdated(zoneID: zoneID, token: serverToken))
        }
        
        var changes = false
        
        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            changes = true
            core.fire(event: CloudKitDeleted(recordID: recordID))
        }
        
        operation.recordChangedBlock = { record in
            guard let ObjectType = self.objectType(for: record) else { return }
            changes = true
            do {
                var object = try ObjectType.init(record: record)
                object.modifiedDate = Date()
                core.fire(event: CloudKitUpdated(object))
            } catch {
                core.fire(event: CloudKitRecordError(error, for: record))
            }
        }
        
        operation.recordZoneFetchCompletionBlock = { zoneID, serverToken, clientToken, moreComing, error in
            core.fire(event: CloudKitServerChangeTokenUpdated(zoneID: zoneID, token: serverToken))
            if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .fetch))
            } else {
                core.fire(event: CloudKitOperationUpdated(status: .completed, type: .fetch))
            }
            self.completion?(changes)
        }
        
        operation.qualityOfService = .userInitiated
        
        if privateDatabase {
            CKContainer.default().privateCloudDatabase.add(operation)
        } else {
            CKContainer.default().publicCloudDatabase.add(operation)
        }
        
    }
    
    fileprivate func objectType(for record: CKRecord) -> CloudKitSyncable.Type? {
        let filtered = objectTypes.filter { $0.recordType == record.recordType }
        return filtered.first
    }
    
}
