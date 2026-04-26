import Foundation
import SwiftData

/// Deliberately empty: InkNoMi starts blank and creates boards only on explicit user action.
enum LibrarySeedService {
    static func seedIfNeeded(in context: ModelContext) {
        _ = context
    }
}
