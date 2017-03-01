/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct FetchCloudKitRecord<T: CloudKitSyncable, U: State>: Command {
    
    public var record: T
    public var completion: (() -> Void)?
    public var privateDatabase: Bool
    
    public init(for record: T, privateDatabase: Bool = true, completion: (() -> Void)? = nil) {
        self.record = record
        self.privateDatabase = privateDatabase
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        if self.privateDatabase {
            CKContainer.default().privateCloudDatabase.fetch(withRecordID: record.cloudKitRecordID) { record, error in
                self.process(record, error: error, state: state, core: core)
            }
        } else {
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: record.cloudKitRecordID) { record, error in
                self.process(record, error: error, state: state, core: core)
            }
        }
    }
    
    private func process(_ record: CKRecord?, error: Error?, state: U, core: Core<U>) {
        defer { completion?() }
        if let error = error {
            core.fire(event: CloudKitRecordFetchError(error: error))
        } else if let record = record {
            do {
                var object = try T(record: record)
                object.modifiedDate = Date()
                core.fire(event: CloudKitUpdated(object))
            } catch {
                core.fire(event: CloudKitRecordError<T>(error, for: record))
            }
        } else {
            core.fire(event: CloudKitRecordFetchError(error: CloudKitFetchError.unknown))
        }
    }
    
}
