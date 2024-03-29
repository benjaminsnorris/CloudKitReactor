/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

@available(iOS, introduced: 8.0, deprecated: 11.0, message: "No longer supported, will cease working at some point in the future")
public struct UpdateCloudKitBadge<U: State>: Command {
    
    let badgeCount: Int
    let completion: () -> Void
    
    public init(to count: Int, completion: @escaping (() -> Void) = { }) {
        badgeCount = count
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        let operation = CKModifyBadgeOperation(badgeValue: badgeCount)
        operation.modifyBadgeCompletionBlock = { error in
            if let error = error {
                core.fire(event: CloudKitBadgeError(error: error))
            } else {
                core.fire(event: CloudKitBadgeUpdated(badgeCount: self.badgeCount))
            }
            self.completion()
        }
        operation.qualityOfService = .userInitiated
        CKContainer.default().add(operation)
    }
    
}
