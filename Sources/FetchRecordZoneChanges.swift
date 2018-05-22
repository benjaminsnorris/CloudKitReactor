/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct FetchRecordZoneChanges<U: State>: Command {
    
    public let objectTypes: [CloudKitSyncable.Type]
    public var recordZoneIDs: [CKRecordZoneID]
    public var recordZoneChangesOptions: [CKFetchRecordZoneChangesOptions]
    public var zoneChangeTokens: [CKRecordZoneID: CKServerChangeToken]
    public var databaseScope: CKDatabaseScope
    public var completion: ((_ changes: Bool) -> Void)?
    
    fileprivate var defaultZoneOnly: Bool {
        return recordZoneIDs == [CloudKitReactorConstants.zoneID] && recordZoneChangesOptions.isEmpty
    }
    
    public init(with objectTypes: [CloudKitSyncable.Type], recordZoneIDs: [CKRecordZoneID] = [CloudKitReactorConstants.zoneID], recordZoneChangesOptions: [CKFetchRecordZoneChangesOptions] = [], zoneChangeTokens: [CKRecordZoneID: CKServerChangeToken] = [:], databaseScope: CKDatabaseScope = .private, completion: ((_ changes: Bool) -> Void)? = nil) {
        self.objectTypes = objectTypes
        self.recordZoneIDs = recordZoneIDs
        self.recordZoneChangesOptions = recordZoneChangesOptions
        self.zoneChangeTokens = zoneChangeTokens
        self.databaseScope = databaseScope
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        guard !recordZoneIDs.isEmpty else {
            completion?(false)
            return
        }
        let operation = CKFetchRecordZoneChangesOperation()
        operation.recordZoneIDs = recordZoneIDs
        if defaultZoneOnly {
            let options = CKFetchRecordZoneChangesOptions()
            options.previousServerChangeToken = zoneChangeTokens[CloudKitReactorConstants.zoneID]
            operation.optionsByRecordZoneID = [CloudKitReactorConstants.zoneID: options]
        } else {
            var allOptions = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
            for (index, zoneID) in recordZoneIDs.enumerated() {
                let options: CKFetchRecordZoneChangesOptions
                if index < recordZoneChangesOptions.count {
                    options = recordZoneChangesOptions[index]
                } else {
                    options = CKFetchRecordZoneChangesOptions()
                }
                options.previousServerChangeToken = zoneChangeTokens[zoneID]
                allOptions[zoneID] = options
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
            changes = true
            if let share = record as? CKShare {
                core.fire(event: CloudKitUpdated(share))
            }
            guard let ObjectType = self.objectType(for: record) else { return }
            do {
                let object = try ObjectType.init(record: record)
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
    
    fileprivate func objectType(for record: CKRecord) -> CloudKitSyncable.Type? {
        let filtered = objectTypes.filter { $0.recordType == record.recordType }
        return filtered.first
    }
    
}
