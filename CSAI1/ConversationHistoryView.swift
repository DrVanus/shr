import SwiftUI

struct ConversationHistoryView: View {
    // Passed in from parent
    var conversations: [Conversation]
    
    let onSelectConversation: (Conversation) -> Void
    let onNewChat: () -> Void
    let onDeleteConversation: (Conversation) -> Void
    let onRenameConversation: (Conversation, String) -> Void
    let onTogglePin: (Conversation) -> Void
    
    // Local state for searching & rename popovers
    @State private var searchText: String = ""
    @State private var conversationToRename: Conversation? = nil
    @State private var newTitle: String = ""
    
    // Whether the search bar is visible
    @State private var showSearch: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Slight gradient or solid black
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.07, green: 0.07, blue: 0.07)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Toggleable search bar
                    if showSearch {
                        searchBar()
                            .transition(.opacity)
                            .animation(.easeInOut, value: showSearch)
                    }
                    
                    conversationList()
                }
                
                // Floating "New Chat" button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: onNewChat) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                                .padding(18)
                                .background(Color.yellow)
                                .clipShape(Circle())
                                .shadow(color: .yellow.opacity(0.4), radius: 6, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            // Single magnifying glass button toggles search
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut) {
                            showSearch.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .imageScale(.large)
                    }
                    .foregroundColor(.white)
                }
            })
        }
        .presentationDragIndicator(.visible)
        // Rename alert
        .alert("Rename Conversation",
               isPresented: Binding<Bool>(
                get: { conversationToRename != nil },
                set: { if !$0 { conversationToRename = nil } }
               ),
               actions: {
                   TextField("New Title", text: $newTitle)
                   Button("Save", action: renameConfirmed)
                   Button("Cancel", role: .cancel) {}
               },
               message: {
                   Text("Enter a new title:")
               }
        )
    }
}

// MARK: - Subviews
extension ConversationHistoryView {
    
    private func searchBar() -> some View {
        HStack {
            TextField("Search Conversations", text: $searchText)
                .padding(10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .yellow.opacity(0.3), radius: 4, x: 0, y: 0)
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .padding(.bottom, 4)
    }
    
    private func conversationList() -> some View {
        // Filter by search
        let filtered = conversations.filter { convo in
            searchText.isEmpty ||
            convo.title.localizedCaseInsensitiveContains(searchText)
        }
        
        let pinnedConvos = filtered.filter { $0.pinned }
        let unpinnedConvos = filtered.filter { !$0.pinned }
        
        return List {
            if !pinnedConvos.isEmpty {
                Section(header: pinnedHeader()) {
                    ForEach(pinnedConvos, id: \.id) { convo in
                        conversationRow(convo)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            
            Section(header: allConversationsHeader()) {
                ForEach(unpinnedConvos, id: \.id) { convo in
                    conversationRow(convo)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
    
    private func pinnedHeader() -> some View {
        HStack {
            Text("PINNED")
                .foregroundColor(.yellow)
                .font(.headline)
            Spacer()
        }
        .padding(.vertical, 4)
        .background(Color.clear)
    }
    
    private func allConversationsHeader() -> some View {
        HStack {
            Text("ALL CONVERSATIONS")
                .foregroundColor(.white)
                .font(.headline)
            Spacer()
        }
        .padding(.vertical, 4)
        .background(Color.clear)
    }
    
    private func conversationRow(_ convo: Conversation) -> some View {
        HStack {
            if convo.pinned {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            Text(convo.title)
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectConversation(convo)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDeleteConversation(convo)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                conversationToRename = convo
                newTitle = convo.title
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.blue)
            
            Button {
                onTogglePin(convo)
            } label: {
                if convo.pinned {
                    Label("Unpin", systemImage: "pin.slash")
                } else {
                    Label("Pin", systemImage: "pin.fill")
                }
            }
            .tint(.yellow)
        }
        .contextMenu {
            Button(convo.pinned ? "Unpin" : "Pin") {
                onTogglePin(convo)
            }
            Button("Rename") {
                conversationToRename = convo
                newTitle = convo.title
            }
            Button("Delete", role: .destructive) {
                onDeleteConversation(convo)
            }
        }
    }
    
    private func renameConfirmed() {
        guard let convo = conversationToRename else { return }
        onRenameConversation(convo, newTitle)
        conversationToRename = nil
        newTitle = ""
    }
}
