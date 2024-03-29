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
    public var recordZoneIDs: [CKRecordZone.ID]
    public var recordZoneChangesOptions: [CKFetchRecordZoneChangesOperation.ZoneConfiguration]
    public var zoneChangeTokens: [CKRecordZone.ID: CKServerChangeToken]
    public var databaseScope: CKDatabase.Scope
    public var completion: ((_ changes: Bool) -> Void)?
    
    fileprivate var defaultZoneOnly: Bool {
        return recordZoneIDs == [CloudKitReactorConstants.zoneID] && recordZoneChangesOptions.isEmpty
    }
    
    public init(with objectTypes: [CloudKitSyncable.Type], recordZoneIDs: [CKRecordZone.ID] = [CloudKitReactorConstants.zoneID], recordZoneChangesOptions: [CKFetchRecordZoneChangesOperation.ZoneConfiguration] = [], zoneChangeTokens: [CKRecordZone.ID: CKServerChangeToken] = [:], databaseScope: CKDatabase.Scope = .private, completion: ((_ changes: Bool) -> Void)? = nil) {
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
            let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            configuration.previousServerChangeToken = zoneChangeTokens[CloudKitReactorConstants.zoneID]
            operation.configurationsByRecordZoneID = [CloudKitReactorConstants.zoneID: configuration]
        } else {
            var allConfigurations = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration]()
            for (index, zoneID) in recordZoneIDs.enumerated() {
                let configuration: CKFetchRecordZoneChangesOperation.ZoneConfiguration
                if index < recordZoneChangesOptions.count {
                    configuration = recordZoneChangesOptions[index]
                } else {
                    configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
                }
                configuration.previousServerChangeToken = zoneChangeTokens[zoneID]
                allConfigurations[zoneID] = configuration
            }
            operation.configurationsByRecordZoneID = allConfigurations
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
        @unknown default:
            fatalError()
        }
        
    }
    
    fileprivate func objectType(for record: CKRecord) -> CloudKitSyncable.Type? {
        let filtered = objectTypes.filter { $0.recordType == record.recordType }
        return filtered.first
    }
    
}
