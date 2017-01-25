/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct CloudKitUpdated<T>: Reactor.Event {
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

public enum CloudKitOperationStatus<T: CloudKitSyncable> {
    case started
    case completed([T])
    case errored(Error)
}

public struct CloudKitOperationUpdated<T: CloudKitSyncable>: CloudKitDataEvent {
    public var status: CloudKitOperationStatus<T>
    public var type: CloudKitOperationType
    
    public init(status: CloudKitOperationStatus<T>, type: CloudKitOperationType) {
        self.status = status
        self.type = type
    }
}

public struct CloudKitStatusRetrieved: CloudKitDataEvent {
    public var status: CKAccountStatus
    public var error: Error?
}
