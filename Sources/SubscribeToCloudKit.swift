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
                // TODO: Handle failure
                if let error = error {
                    print("status=subscription-failed error=\(error)")
                } else {
                    print("status=subscription-successful")
                }
            }
        } else {
            CKContainer.default().publicCloudDatabase.save(subscription) { subscription, error in
                // TODO: Handle failure
                if let error = error {
                    print("status=subscription-failed error=\(error)")
                } else {
                    print("status=subscription-successful")
                }
            }
        }
    }
    
}
