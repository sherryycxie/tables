import SwiftUI

struct NewHomeView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager

    @State private var isShowingQuickStartMenu = false
    @State private var isShowingQuickWin = false
    @State private var isShowingDeepReflection = false
    @State private var isShowingCreateTable = false
    @State private var isShowingProfile = false
    @State private var isShowingAllTables = false
    @State private var selectedTable: SupabaseTable?
    @State private var selectedReflection: SupabaseReflection?
    @State private var prefilledPrompt: DailyPrompt?
    @State private var isShowingCustomPromptEntry = false
    @State private var customPromptText = ""
    @State private var isShowingAllReflections = false

    private var greeting: String {
        let base = GreetingHelper.greeting()
        if let firstName = supabaseManager.currentFirstName, !firstName.isEmpty {
            return "\(base), \(firstName)"
        }
        return base
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                        header
                        DailyPromptsCarouselView(
                            prompts: DailyPrompts.todaysPrompts,
                            onSelectPrompt: { prompt in
                                prefilledPrompt = prompt
                            },
                            onWriteOwn: {
                                isShowingCustomPromptEntry = true
                            }
                        )
                        YourGardenView(
                            onViewAll: {
                                isShowingAllReflections = true
                            },
                            onSelectReflection: { reflection in
                                selectedReflection = reflection
                            }
                        )
                        RecentTablesSectionView(
                            tables: supabaseManager.tables,
                            onViewAll: {
                                isShowingAllTables = true
                            },
                            onSelectTable: { table in
                                selectedTable = table
                            }
                        )
                    }
                    .padding(.horizontal, DesignSystem.Padding.screen)
                    .padding(.top, DesignSystem.Spacing.medium)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await supabaseManager.fetchTables()
                    await supabaseManager.fetchReflections()
                }

                PrimaryButton(title: "Quick Start", systemImage: "plus") {
                    isShowingQuickStartMenu = true
                }
                .padding(.trailing, DesignSystem.Padding.screen)
                .padding(.bottom, DesignSystem.Padding.screen)
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingAllTables) {
                SupabaseHomeView()
            }
            .navigationDestination(isPresented: $isShowingAllReflections) {
                AllReflectionsView()
            }
            .navigationDestination(item: $selectedTable) { table in
                SupabaseTableDetailView(table: table)
            }
            .sheet(isPresented: $isShowingQuickStartMenu) {
                QuickStartMenuView(
                    onLogWin: {
                        isShowingQuickStartMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isShowingQuickWin = true
                        }
                    },
                    onDeepReflection: {
                        isShowingQuickStartMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isShowingDeepReflection = true
                        }
                    },
                    onStartTable: {
                        isShowingQuickStartMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isShowingCreateTable = true
                        }
                    }
                )
                .presentationDetents([.height(320)])
            }
            .sheet(isPresented: $isShowingQuickWin) {
                ReflectionComposerView(reflectionType: .quickWin)
            }
            .sheet(isPresented: $isShowingDeepReflection) {
                ReflectionComposerView(reflectionType: .deepReflection)
            }
            .sheet(isPresented: $isShowingCreateTable) {
                SupabaseCreateTableView()
            }
            .sheet(isPresented: $isShowingProfile) {
                ProfileView()
            }
            .sheet(item: $prefilledPrompt) { prompt in
                ReflectionComposerView(
                    reflectionType: .deepReflection,
                    prefilledPrompt: prompt
                )
            }
            .sheet(item: $selectedReflection) { reflection in
                ReflectionDetailView(reflection: reflection)
            }
            .alert("Write your own prompt", isPresented: $isShowingCustomPromptEntry) {
                TextField("What do you want to reflect on?", text: $customPromptText)
                Button("Cancel", role: .cancel) {
                    customPromptText = ""
                }
                Button("Reflect") {
                    if !customPromptText.isEmpty {
                        prefilledPrompt = DailyPrompt(
                            question: customPromptText,
                            explanation: ""
                        )
                        customPromptText = ""
                    }
                }
            } message: {
                Text("Enter a question or topic for your reflection.")
            }
        }
    }

    private var header: some View {
        HStack {
            Text(greeting)
                .font(.system(size: 28, weight: .bold))

            Spacer()

            Button {
                isShowingProfile = true
            } label: {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(DesignSystem.Colors.primary)
                    )
            }
        }
    }
}

// Make DailyPrompt Identifiable for sheet binding
extension DailyPrompt: Identifiable {
    var id: String { question }
}

#Preview {
    NewHomeView()
        .environmentObject(SupabaseManager())
}
