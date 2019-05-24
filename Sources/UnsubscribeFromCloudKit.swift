/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit
import Reactor

public struct UnsubscribeFromCloudKit<U: State>: Command {
    
    let databaseScope: CKDatabase.Scope
    let identifiers: [String]
    
    public init(with identifiers: [String], databaseScope: CKDatabase.Scope = .private) {
        self.databaseScope = databaseScope
        self.identifiers = identifiers
    }
    
    public init(with identifier: String, databaseScope: CKDatabase.Scope = .private) {
        self.databaseScope = databaseScope
        identifiers = [identifier]
    }
    
    public func execute(state: U, core: Core<U>) {
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: identifiers)
        operation.qualityOfService = .utility
        operation.modifySubscriptionsCompletionBlock = { _, deletedSubscriptionIds, error in
            if let error = error {
                core.fire(event: CloudKitSubscriptionError(error: error))
            } else if let deletedIds = deletedSubscriptionIds {
                deletedIds.forEach { deletedId in
                    let type: CloudKitSubscriptionType
                    switch self.databaseScope {
                    case .private:
                        type = .privateDatabase
                    case .shared:
                        type = .sharedDatabase
                    case .public:
                        type = .publicDatabase
                    }
                    core.fire(event: CloudKitSubscriptionRemoved(type: type, subscriptionId: deletedId))
                }
            }
        }
        
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
