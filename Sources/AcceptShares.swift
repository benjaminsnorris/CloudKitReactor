/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor
import CloudKit

public struct AcceptShares<U: State>: Command {
    
    public var metadatas: [CKShareMetadata]
    public var completion: ((Error?) -> Void)?
    
    public init(with metadatas: [CKShareMetadata], completion: ((Error?) -> Void)? = nil) {
        self.metadatas = metadatas
        self.completion = completion
    }
    
    public func execute(state: U, core: Core<U>) {
        let operation = CKAcceptSharesOperation(shareMetadatas: metadatas)
        operation.perShareCompletionBlock = { metadata, share, error in
            if let error = error {
                core.fire(event: CloudKitShareError(error, for: metadata))
            } else if let share = share {
                core.fire(event: CloudKitUpdated(share))
            }
        }
        operation.acceptSharesCompletionBlock = { error in
            self.completion?(error)
        }
        operation.qualityOfService = .userInitiated
        CKContainer.default().add(operation)
    }
    
}
