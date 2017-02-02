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
    public var privateDatabase: Bool

    public init(predicate: NSPredicate = NSPredicate(value: true), options: CKQuerySubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion], notificationInfo: CKNotificationInfo? = nil, privateDatabase: Bool = true) {
        self.predicate = predicate
        self.options = options
        if let notificationInfo = notificationInfo {
            self.notificationInfo = notificationInfo
        } else {
            self.notificationInfo = CKNotificationInfo()
            notificationInfo?.shouldSendContentAvailable = true
        }
        self.privateDatabase = privateDatabase
    }
    
    public func execute(state: U, core: Core<U>) {
        let subscription = CKQuerySubscription(recordType: T.recordType, predicate: predicate, options: options)
        subscription.notificationInfo = notificationInfo
        
        if privateDatabase {
            CKContainer.default().privateCloudDatabase.save(subscription) { subscription, error in
                if let error = error {
                    core.fire(event: CloudKitSubscriptionError(error: error))
                } else {
                    core.fire(event: CloudKitSubscriptionSuccessful())
                }
            }
        } else {
            CKContainer.default().publicCloudDatabase.save(subscription) { subscription, error in
                if let error = error {
                    core.fire(event: CloudKitSubscriptionError(error: error))
                } else {
                    core.fire(event: CloudKitSubscriptionSuccessful())
                }
            }
        }
    }
    
}
