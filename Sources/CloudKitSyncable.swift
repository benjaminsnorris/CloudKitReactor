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
    
    public static var recordType: String { return String(describing: self) }
    
    public var needsSavingToCloudKit: Bool {
        return !isSavedInCloudKit || hasUnsavedChanges
    }
    
    public var isSavedInCloudKit: Bool {
        return encodedSystemFields != nil
    }
    
    public var hasUnsavedChanges: Bool {
        return !cloudKitRecordChanges.isEmpty
    }
    
    public var cloudKitReference: CKReference {
        return CKReference(recordID: cloudKitRecordID, action: .none)
    }
    
    public var parentReference: CKReference? {
        return nil
    }
    
    public var recordToSave: CKRecord? {
        return isSavedInCloudKit ? recordWithChanges : CKRecord(object: self)
    }
    
    public var recordWithChanges: CKRecord? {
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
    
    public var cloudKitRecordID: CKRecordID {
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
    public mutating func recordChanges(from original: Self) {
        let changes = diff(from: original)
        for (key, value) in changes {
            cloudKitRecordChanges[key] = value
        }
    }
    
}

public extension CKRecord {
    
    public convenience init(object: CloudKitSyncable) {
        let recordId = object.cloudKitRecordID
        self.init(recordType: type(of: object).recordType, recordID: recordId)
        for (key, value) in object.cloudKitRecordProperties {
            self[key] = value
        }
        parent = object.parentReference
    }
    
    public var encodedSystemFieldsData: Data {
        let encodedSystemFields = NSMutableData()
        let coder = NSKeyedArchiver.init(forWritingWith: encodedSystemFields)
        coder.requiresSecureCoding = true
        encodeSystemFields(with: coder)
        coder.finishEncoding()
        return encodedSystemFields as Data
    }
    
}
