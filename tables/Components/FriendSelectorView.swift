import SwiftUI

struct FriendSelectorView: View {
    let friends: [String]
    @Binding var selectedFriend: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(friends, id: \.self) { friend in
                    FriendAvatarView(
                        name: friend,
                        isSelected: selectedFriend == friend
                    )
                    .onTapGesture {
                        if selectedFriend == friend {
                            selectedFriend = nil  // Deselect if already selected
                        } else {
                            selectedFriend = friend
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Padding.screen)
        }
    }
}

#Preview {
    @Previewable @State var selectedFriend: String? = "Jane Smith"

    FriendSelectorView(
        friends: ["John Doe", "Jane Smith", "Bob Johnson", "Alice Brown"],
        selectedFriend: $selectedFriend
    )
}
