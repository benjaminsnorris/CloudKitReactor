/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct Updated<T>: Reactor.Event {
    public var payload: T
    
    public init(_ payload: T) {
        self.payload = payload
    }
}

public protocol CloudKitErrorEvent: Reactor.Event {
    var error: Error { get }
}
public protocol CloudKitDataEvent: Reactor.Event { }

public struct CloudKitRecordError<T: CloudKitSyncable>: CloudKitErrorEvent {
    public var error: Error
    public var record: CKRecord
    
    public init(_ error: Error, for record: CKRecord) {
        self.error = error
        self.record = record
    }
}

public enum CloudKitOperationType {
    case save
    case fetch
    case delete
}

public enum CloudKitOperationStatus {
    case started
    case completed([CloudKitSyncable])
    case errored(Error)
}

public struct CloudKitOperationUpdated<T: CloudKitSyncable>: CloudKitDataEvent {
    public var status: CloudKitOperationStatus
    public var type: CloudKitOperationType
    
    public init(status: CloudKitOperationStatus, type: CloudKitOperationType) {
        self.status = status
        self.type = type
    }
}
