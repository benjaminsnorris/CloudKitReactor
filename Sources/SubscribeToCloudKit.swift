/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit
import Reactor

public struct SubscribeToCloudKit<T: CloudKitSyncable, U: State>: Command {
    
    public var predicate: NSPredicate
    public var options: CKQuerySubscriptionOptions
    public var notificationInfo: CKNotificationInfo
    public var subscriptionID: String?
    public var databaseScope: CKDatabaseScope
    public var zoneID: CKRecordZoneID

    public init(predicate: NSPredicate = NSPredicate(value: true), options: CKQuerySubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion], notificationInfo: CKNotificationInfo? = nil, subscriptionID: String? = nil, databaseScope: CKDatabaseScope = .private, zoneID: CKRecordZoneID = CloudKitReactorConstants.zoneID) {
        self.predicate = predicate
        self.options = options
        if let notificationInfo = notificationInfo {
            self.notificationInfo = notificationInfo
        } else {
            self.notificationInfo = CKNotificationInfo()
            notificationInfo?.shouldSendContentAvailable = true
        }
        self.subscriptionID = subscriptionID
        self.databaseScope = databaseScope
        self.zoneID = zoneID
    }
    
    public func execute(state: U, core: Core<U>) {
        let subscription: CKQuerySubscription
        if let subscriptionID = subscriptionID {
            subscription = CKQuerySubscription(recordType: T.recordType, predicate: predicate, subscriptionID: subscriptionID, options: options)
        } else {
            subscription = CKQuerySubscription(recordType: T.recordType, predicate: predicate, options: options)
        }
        subscription.notificationInfo = notificationInfo
        subscription.zoneID = zoneID
        
        let container = CKContainer.default()
        switch databaseScope {
        case .private:
            container.privateCloudDatabase.save(subscription) { subscription, error in
                if let error = error {
                    core.fire(event: CloudKitSubscriptionError(error: error))
                } else {
                    core.fire(event: CloudKitSubscriptionSuccessful(type: .privateQuery, subscriptionID: self.subscriptionID))
                }
            }
        case .shared:
            container.sharedCloudDatabase.save(subscription) { subscription, error in
                if let error = error {
                    core.fire(event: CloudKitSubscriptionError(error: error))
                } else {
                    core.fire(event: CloudKitSubscriptionSuccessful(type: .sharedQuery, subscriptionID: self.subscriptionID))
                }
            }
        case .public:
            container.publicCloudDatabase.save(subscription) { subscription, error in
                if let error = error {
                    core.fire(event: CloudKitSubscriptionError(error: error))
                } else {
                    core.fire(event: CloudKitSubscriptionSuccessful(type: .publicQuery, subscriptionID: self.subscriptionID))
                }
            }
        }
    }
    
}
