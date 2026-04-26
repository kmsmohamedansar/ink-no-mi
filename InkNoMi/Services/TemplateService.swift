import Foundation

enum TemplateService {
    /// Centralized template board generation used by Home creation flows.
    static func makeBoardState(for template: WorkspaceTemplate) -> CanvasBoardState {
        template.makeInitialCanvasState()
    }
}
