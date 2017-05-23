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
    
    public init() { }
    
    public func execute(state: U, core: Core<U>) {
        CKContainer.default().fetchUserRecordID { recordID, error in
            if let error = error {
                core.fire(event: CloudKitRecordFetchError(error: error))
            } else if let recordID = recordID {
                core.fire(event: CloudKitCurrentUserIDRetrieved(recordID: recordID))
            } else {
                core.fire(event: CloudKitRecordFetchError(error: CloudKitFetchError.unknown))
            }
        }
    }
    
}
