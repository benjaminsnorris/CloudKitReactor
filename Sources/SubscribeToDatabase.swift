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
    
    public var databaseScope: CKDatabase.Scope
    public var subscriptionID: String
    public var notificationInfo: CKSubscription.NotificationInfo
    
    public init(databaseScope: CKDatabase.Scope = .private, subscriptionID: String? = nil, notificationInfo: CKSubscription.NotificationInfo? = nil) {
        self.databaseScope = databaseScope
        if let subscriptionID = subscriptionID {
            self.subscriptionID = subscriptionID
        } else {
            self.subscriptionID = databaseScope == .private ? CloudKitReactorConstants.privateDatabaseSubscription : CloudKitReactorConstants.sharedDatabaseSubscription
        }
        if let notificationInfo = notificationInfo {
            self.notificationInfo = notificationInfo
        } else {
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            self.notificationInfo = notificationInfo
        }
    }
    
    public func execute(state: U, core: Core<U>) {
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
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
                @unknown default:
                    fatalError()
                }
                core.fire(event: CloudKitSubscriptionSuccessful(type: type, subscriptionID: self.subscriptionID))
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
        @unknown default:
            fatalError()
        }
    }
    
}
