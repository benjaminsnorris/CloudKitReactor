/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct FetchCurrentUserID<U: State>: Command {
    
    public var onComplete: ((CKRecordID?) -> Void)?
    
    public init(onComplete: ((CKRecordID?) -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    public func execute(state: U, core: Core<U>) {
        CKContainer.default().fetchUserRecordID { recordID, error in
            if let error = error {
                core.fire(event: CloudKitRecordFetchError(error: error))
                self.onComplete?(nil)
            } else if let recordID = recordID {
                core.fire(event: CloudKitCurrentUserIDRetrieved(recordID: recordID))
                self.onComplete?(recordID)
            } else {
                core.fire(event: CloudKitRecordFetchError(error: CloudKitFetchError.unknown))
                self.onComplete?(nil)
            }
        }
    }
    
}
