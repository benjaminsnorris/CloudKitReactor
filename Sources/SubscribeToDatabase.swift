/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit
import Reactor

public struct SubscribeToDatabase<U: State>: Command {
    
    public var databaseScope: CKDatabaseScope
    public var subscriptionID: String
    
    public init(databaseScope: CKDatabaseScope = .private, subscriptionID: String? = nil) {
        self.databaseScope = databaseScope
        if let subscriptionID = subscriptionID {
            self.subscriptionID = subscriptionID
        } else {
            self.subscriptionID = databaseScope == .private ? CloudKitReactorConstants.privateDatabaseSubscription : CloudKitReactorConstants.sharedDatabaseSubscription
        }
    }
    
    public func execute(state: U, core: Core<U>) {
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
        operation.modifySubscriptionsCompletionBlock = { savedSubscriptions, _, error in
            if let error = error {
                core.fire(event: CloudKitSubscriptionError(error: error))
            } else {
                let type: CloudKitSubscriptionType
                switch self.databaseScope {
                case .private:
                    type = .privateDatabase
                case .shared:
                    type = .sharedDatabase
                case .public:
                    type = .publicDatabase
                }
                core.fire(event: CloudKitSubscriptionSuccessful(type: type))
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
