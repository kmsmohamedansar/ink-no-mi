import SwiftData

/// Central place for SwiftData schema and store configuration (migrations, cloud later).
enum ModelContainerFactory {
    static func makeDefault(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([FlowDocument.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // If persistent store migration fails, fallback to in-memory so app can still launch.
            guard !inMemory else {
                fatalError("Ink no Mi: In-memory ModelContainer failed — \(error.localizedDescription)")
            }
            do {
                let inMemoryConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
            } catch {
                fatalError("Ink no Mi: ModelContainer recovery failed — \(error.localizedDescription)")
            }
        }
    }
}
