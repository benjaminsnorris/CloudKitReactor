/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit

protocol CloudKitSyncable {
    init(record: CKRecord) throws
    
    var cloudKitRecordID: CKRecordID? { get }
    var modifiedDate: Date { get set }
    func cloudKitRecordProperties() -> [String: CKRecordValue?]
    
    static var recordType: String { get }
    var cloudKitReference: CKReference? { get }
}

extension CloudKitSyncable {
    
    static var recordType: String { return String(describing: self) }
    
    var cloudKitReference: CKReference? {
        guard let recordID = cloudKitRecordID else { return nil }
        return CKReference(recordID: recordID, action: .none)
    }
    
}

extension CKRecord {
    
    convenience init(object: CloudKitSyncable) {
        let recordId = object.cloudKitRecordID ?? CKRecordID(recordName: UUID().uuidString)
        self.init(recordType: type(of: object).recordType, recordID: recordId)
        for (key, value) in object.cloudKitRecordProperties() {
            self[key] = value
        }
    }
    
}
