/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct DiscoverCurrentUserIdentity<U: State>: Command {
    
    public init() { }
    
    public func execute(state: U, core: Core<U>) {
        core.fire(command: FetchCurrentUserID { recordID in
            guard let recordID = recordID else { return }
            CKContainer.default().discoverUserIdentity(withUserRecordID: recordID) { identity, error in
                if let error = error {
                    core.fire(event: CloudKitRecordFetchError(error: error))
                } else if let identity = identity {
                    core.fire(event: CloudKitCurrentUserIdentityRetrieved(identity: identity))
                } else {
                    core.fire(event: CloudKitRecordFetchError(error: CloudKitFetchError.unknown))
                }
            }
        })
    }
    
}
