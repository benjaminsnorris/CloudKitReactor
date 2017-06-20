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
    public var privateDatabase: Bool
    public var zoneID: CKRecordZoneID

    public init(predicate: NSPredicate = NSPredicate(value: true), options: CKQuerySubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion], notificationInfo: CKNotificationInfo? = nil, subscriptionID: String? = nil, privateDatabase: Bool = true, zoneID: CKRecordZoneID = CloudKitReactorConstants.zoneID) {
        self.predicate = predicate
        self.options = options
        if let notificationInfo = notificationInfo {
            self.notificationInfo = notificationInfo
        } else {
            self.notificationInfo = CKNotificationInfo()
            notificationInfo?.shouldSendContentAvailable = true
        }
        self.subscriptionID = subscriptionID
        self.privateDatabase = privateDatabase
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
        
        if privateDatabase {
            CKContainer.default().privateCloudDatabase.save(subscription) { subscription, error in
                if let error = error {
                    core.fire(event: CloudKitSubscriptionError(error: error))
                } else {
                    core.fire(event: CloudKitSubscriptionSuccessful(type: .privateQuery))
                }
            }
        } else {
            CKContainer.default().publicCloudDatabase.save(subscription) { subscription, error in
                if let error = error {
                    core.fire(event: CloudKitSubscriptionError(error: error))
                } else {
                    core.fire(event: CloudKitSubscriptionSuccessful(type: .publicQuery))
                }
            }
        }
    }
    
}
