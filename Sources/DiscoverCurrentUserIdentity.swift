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
            let lookupInfo = CKUserIdentityLookupInfo(userRecordID: recordID)
            let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [lookupInfo])
            operation.userIdentityDiscoveredBlock = { identity, lookupInfo in
                core.fire(event: CloudKitCurrentUserIdentityRetrieved(identity: identity))
            }
            operation.discoverUserIdentitiesCompletionBlock = { error in
                if let error = error {
                    core.fire(event: CloudKitRecordFetchError(error: error))
                }
            }
            operation.queuePriority = .veryHigh
            CKContainer.default().add(operation)
        })
    }
    
}
