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
    public var databaseChangeToken: CKServerChangeToken?
    public var zoneChangeTokens: [CKRecordZone.ID: CKServerChangeToken]
    public var databaseScope: CKDatabase.Scope
    public var completion: ((_ changes: Bool) -> Void)?
    
    public init(with objectTypes: [CloudKitSyncable.Type], databaseChangeToken: CKServerChangeToken? = nil, zoneChangeTokens: [CKRecordZone.ID: CKServerChangeToken] = [:], databaseScope: CKDatabase.Scope = .private, completion: ((_ changes: Bool) -> Void)? = nil) {
        self.objectTypes = objectTypes
        self.databaseChangeToken = databaseChangeToken
        self.zoneChangeTokens = zoneChangeTokens
        self.databaseScope = databaseScope
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        var changedZoneIDs = [CKRecordZone.ID]()
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: databaseChangeToken)
        operation.recordZoneWithIDChangedBlock = { zoneID in
            changedZoneIDs.append(zoneID)
        }
        operation.recordZoneWithIDWasDeletedBlock = { zoneID in
            // TODO: Handle deleted record zone
        }
        operation.changeTokenUpdatedBlock = { token in
            core.fire(event: CloudKitDatabaseServerChangeTokenUpdated(databaseScope: self.databaseScope, token: token))
        }
        operation.fetchDatabaseChangesCompletionBlock = { token, moreComing, error in
            core.fire(event: CloudKitDatabaseServerChangeTokenUpdated(databaseScope: self.databaseScope, token: token))
            if let error = error {
                core.fire(event: CloudKitOperationUpdated(status: .errored(error), type: .fetch))
                self.completion?(false)
            } else {
                core.fire(command: FetchRecordZoneChanges(with: self.objectTypes, recordZoneIDs: changedZoneIDs, zoneChangeTokens: self.zoneChangeTokens, databaseScope: self.databaseScope, completion: self.completion))
            }
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

}
