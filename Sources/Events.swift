/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

struct Updated<T>: Reactor.Event {
    var payload: T
    
    init(_ payload: T) {
        self.payload = payload
    }
}

protocol CloudKitErrorEvent: Reactor.Event {
    var error: Error { get }
}
protocol CloudKitDataEvent: Reactor.Event { }

struct CloudKitRecordError<T: CloudKitSyncable>: CloudKitErrorEvent {
    var error: Error
    var record: CKRecord
    
    init(_ error: Error, for record: CKRecord) {
        self.error = error
        self.record = record
    }
}

enum OperationType {
    case save
    case fetch
}

enum OperationStatus {
    case started
    case completed
    case errored(Error)
}

struct CloudKitOperationUpdated<T: CloudKitSyncable>: CloudKitDataEvent {
    var status: OperationStatus
    var type: OperationType
}
