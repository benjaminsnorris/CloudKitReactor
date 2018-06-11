/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public protocol CloudKitErrorEvent: Reactor.Event {
    var error: Error { get }
}
public protocol CloudKitDataEvent: Reactor.Event { }

public struct CloudKitUpdated<T>: CloudKitDataEvent {
    public var payload: T
    
    public init(_ payload: T) {
        self.payload = payload
    }
}

public struct CloudKitDeleted: CloudKitDataEvent {
    public var recordID: CKRecordID
}

public struct CloudKitRecordError: CloudKitErrorEvent {
    public var error: Error
    public var record: CKRecord
    
    public init(_ error: Error, for record: CKRecord) {
        self.error = error
        self.record = record
    }
}

public enum CloudKitFetchError: Error {
    case unknown
}

public struct CloudKitRecordFetchError: CloudKitErrorEvent {
    public var error: Error
}

public enum CloudKitOperationType {
    case save
    case fetch
    case delete
}

public enum CloudKitOperationStatus {
    case started
    case completed
    case errored(Error)
}

public struct CloudKitOperationUpdated: CloudKitDataEvent {
    public var status: CloudKitOperationStatus
    public var type: CloudKitOperationType
    
    public init(status: CloudKitOperationStatus, type: CloudKitOperationType) {
        self.status = status
        self.type = type
    }
}

public struct CloudKitAccountChanged: CloudKitDataEvent {
    public init() { }
}

public struct CloudKitStatusRetrieved: CloudKitDataEvent {
    public var status: CKAccountStatus
    public var error: Error?
}

public struct CloudKitDefaultCustomZoneCreated: CloudKitDataEvent {
    public var zoneID: CKRecordZoneID
}

public struct CloudKitDefaultCustomZoneFound: CloudKitDataEvent {
    public init() { }
}

public struct CloudKitUserDiscoverabilityRetrieved: CloudKitDataEvent {
    public var status: CKApplicationPermissionStatus
    public var error: Error?
}

public struct CloudKitCurrentUserIDRetrieved: CloudKitDataEvent {
    public var recordID: CKRecordID
}

public struct CloudKitCurrentUserIdentityRetrieved: CloudKitDataEvent {
    public var identity: CKUserIdentity
}

public enum CloudKitSubscriptionType {
    case publicQuery
    case privateQuery
    case sharedQuery
    case privateDatabase
    case sharedDatabase
    case publicDatabase
}

public struct CloudKitSubscriptionSuccessful: CloudKitDataEvent {
    public var type: CloudKitSubscriptionType
    public var subscriptionID: String?
}

public struct CloudKitSubscriptionError: CloudKitErrorEvent {
    public var error: Error
}

public struct CloudKitBadgeError: CloudKitErrorEvent {
    public var error: Error
}

public struct CloudKitBadgeUpdated: CloudKitDataEvent {
    public var badgeCount: Int
}

public struct CloudKitServerChangeTokenUpdated: CloudKitDataEvent {
    public var zoneID: CKRecordZoneID
    public var token: CKServerChangeToken?
}

public struct CloudKitDatabaseServerChangeTokenUpdated: CloudKitDataEvent {
    public var databaseScope: CKDatabaseScope
    public var token: CKServerChangeToken?
}

public struct CloudKitShareError: CloudKitErrorEvent {
    public var error: Error
    public var metadata: CKShareMetadata
    public init(_ error: Error, for metadata: CKShareMetadata) {
        self.error = error
        self.metadata = metadata
    }
}
