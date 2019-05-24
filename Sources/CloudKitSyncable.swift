/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit

public protocol CloudKitSyncable {
    init(record: CKRecord) throws
    
    var encodedSystemFields: Data? { get }
    var cloudKitRecordProperties: [String: CKRecordValue?] { get }
    var cloudKitRecordChanges: [String: Any?] { get set }
    
    var cloudKitRecordID: CKRecordID { get }
    static var recordType: String { get }
    var cloudKitReference: CKReference { get }
    var parentReference: CKReference? { get }
    
    var needsSavingToCloudKit: Bool { get }
    var isSavedInCloudKit: Bool { get }
    var hasUnsavedChanges: Bool { get }
    var recordToSave: CKRecord? { get }
    var recordWithChanges: CKRecord? { get }
}

public extension CloudKitSyncable {
    
    static var recordType: String { return String(describing: self) }
    
    var needsSavingToCloudKit: Bool {
        return !isSavedInCloudKit || hasUnsavedChanges
    }
    
    var isSavedInCloudKit: Bool {
        return encodedSystemFields != nil
    }
    
    var hasUnsavedChanges: Bool {
        return !cloudKitRecordChanges.isEmpty
    }
    
    var cloudKitReference: CKReference {
        return CKReference(recordID: cloudKitRecordID, action: .none)
    }
    
    var parentReference: CKReference? {
        return nil
    }
    
    var recordToSave: CKRecord? {
        return isSavedInCloudKit ? recordWithChanges : CKRecord(object: self)
    }
    
    var recordWithChanges: CKRecord? {
        guard hasUnsavedChanges, let encodedSystemFields = encodedSystemFields else { return nil }
        let coder = NSKeyedUnarchiver(forReadingWith: encodedSystemFields)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        for (key, value) in cloudKitRecordChanges {
            record?[key] = value as? CKRecordValue
        }
        return record
    }
    
}

public protocol CloudKitIdentifiable {
    var identifier: String { get }
}

public extension CloudKitSyncable where Self: CloudKitIdentifiable {
    
    var cloudKitRecordID: CKRecordID {
        return CKRecordID(recordName: identifier, zoneID: CloudKitReactorConstants.zoneID)
    }
    
}

public protocol CloudKitDiffable: CloudKitSyncable {
    func diff(from original: Self) -> [String: Any]
    mutating func recordChanges(from original: Self)
}

public extension CloudKitDiffable {
    
    /// Records changes to an object in `cloudKitRecordChanges` to be persisted.
    ///
    /// - Parameter original: Original object before being modified
    mutating func recordChanges(from original: Self) {
        let changes = diff(from: original)
        for (key, value) in changes {
            cloudKitRecordChanges[key] = value
        }
    }
    
}

public extension CKRecord {
    
    convenience init(object: CloudKitSyncable) {
        let recordId = object.cloudKitRecordID
        self.init(recordType: type(of: object).recordType, recordID: recordId)
        for (key, value) in object.cloudKitRecordProperties {
            self[key] = value
        }
        parent = object.parentReference
    }
    
    var encodedSystemFieldsData: Data {
        let encodedSystemFields = NSMutableData()
        let coder = NSKeyedArchiver.init(forWritingWith: encodedSystemFields)
        coder.requiresSecureCoding = true
        encodeSystemFields(with: coder)
        coder.finishEncoding()
        return encodedSystemFields as Data
    }
    
}
