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
    public var options: CKQuerySubscription.Options
    public var notificationInfo: CKSubscription.NotificationInfo
    public var subscriptionID: String?
    public var databaseScope: CKDatabase.Scope
    public var zoneID: CKRecordZone.ID

    public init(predicate: NSPredicate = NSPredicate(value: true), options: CKQuerySubscription.Options = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion], notificationInfo: CKSubscription.NotificationInfo? = nil, subscriptionID: String? = nil, databaseScope: CKDatabase.Scope = .private, zoneID: CKRecordZone.ID = CloudKitReactorConstants.zoneID) {
        self.predicate = predicate
        self.options = options
        if let notificationInfo = notificationInfo {
            self.notificationInfo = notificationInfo
        } else {
            self.notificationInfo = CKSubscription.NotificationInfo()
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
