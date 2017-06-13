/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct UpdateCloudKitBadge<U: State>: Command {
    
    public var badgeCount: Int
    
    public init(to count: Int) {
        badgeCount = count
    }
    
    public func execute(state: U, core: Core<U>) {
        let operation = CKModifyBadgeOperation(badgeValue: badgeCount)
        operation.modifyBadgeCompletionBlock = { error in
            if let error = error {
                core.fire(event: CloudKitBadgeError(error: error))
            } else {
                core.fire(event: CloudKitBadgeUpdated(badgeCount: self.badgeCount))
            }
        }
        operation.qualityOfService = .userInitiated
        CKContainer.default().add(operation)
    }
    
}
