import SwiftUI
import SwiftData

@main
struct TablesApp: App {
    let container: ModelContainer
    @StateObject private var supabaseManager = SupabaseManager()

    init() {
        do {
            let schema = Schema([
                TableModel.self,
                CardModel.self,
                CommentModel.self,
                NudgeModel.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none  // Disabled CloudKit - using Supabase instead
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseManager.isAuthenticated {
                    SupabaseHomeView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(supabaseManager)
        }
        .modelContainer(container)
    }
}
