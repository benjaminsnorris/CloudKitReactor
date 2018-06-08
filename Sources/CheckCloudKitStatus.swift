/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import CloudKit
import Reactor

public struct CheckCloudKitStatus<U: State>: Command {
    
    let completion: (() -> Void)
    
    public init(completion: @escaping (() -> Void) = { }) {
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        CKContainer.default().accountStatus { status, error in
            core.fire(event: CloudKitStatusRetrieved(status: status, error: error))
            self.completion()
        }
    }
    
}
