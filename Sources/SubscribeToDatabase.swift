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
    
    public var privateDatabase: Bool
    public var subscriptionID: String
    
    public init(privateDatabase: Bool = true, subscriptionID: String? = nil) {
        self.privateDatabase = privateDatabase
        if let subscriptionID = subscriptionID {
            self.subscriptionID = subscriptionID
        } else {
            self.subscriptionID = privateDatabase ? CloudKitReactorConstants.privateDatabaseSubscription : CloudKitReactorConstants.sharedDatabaseSubscription
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
                core.fire(event: CloudKitSubscriptionSuccessful(type: self.privateDatabase ? .privateDatabase : .sharedDatabase))
            }
        }
        
        if privateDatabase {
            CKContainer.default().privateCloudDatabase.add(operation)
        } else {
            CKContainer.default().sharedCloudDatabase.add(operation)
        }
    }
    
}
