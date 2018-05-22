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
    public var databaseScope: CKDatabaseScope
    
    public init(for record: T, databaseScope: CKDatabaseScope = .private, completion: (() -> Void)? = nil) {
        self.record = record
        self.databaseScope = databaseScope
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        let container = CKContainer.default()
        switch databaseScope {
        case .private:
            container.privateCloudDatabase.fetch(withRecordID: record.cloudKitRecordID) { record, error in
                self.process(record, error: error, state: state, core: core)
            }
        case .shared:
            container.sharedCloudDatabase.fetch(withRecordID: record.cloudKitRecordID) { record, error in
                self.process(record, error: error, state: state, core: core)
            }
        case .public:
            container.publicCloudDatabase.fetch(withRecordID: record.cloudKitRecordID) { record, error in
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
                let object = try T(record: record)
                core.fire(event: CloudKitUpdated(object))
            } catch {
                core.fire(event: CloudKitRecordError(error, for: record))
            }
        } else {
            core.fire(event: CloudKitRecordFetchError(error: CloudKitFetchError.unknown))
        }
    }
    
}
