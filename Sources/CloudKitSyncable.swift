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
    
    var cloudKitRecordID: CKRecordID { get }
    var modifiedDate: Date { get set }
    func cloudKitRecordProperties() -> [String: CKRecordValue?]
    
    static var recordType: String { get }
    var cloudKitReference: CKReference { get }
    var parentReference: CKReference? { get }
}

public extension CloudKitSyncable {
    
    public static var recordType: String { return String(describing: self) }
    
    public var cloudKitReference: CKReference {
        return CKReference(recordID: cloudKitRecordID, action: .none)
    }
    
    public var parentReference: CKReference? {
        return nil
    }
    
}

public extension CKRecord {
    
    public convenience init(object: CloudKitSyncable) {
        let recordId = object.cloudKitRecordID
        self.init(recordType: type(of: object).recordType, recordID: recordId)
        for (key, value) in object.cloudKitRecordProperties() {
            self[key] = value
        }
        parent = object.parentReference
    }
    
}
