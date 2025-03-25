import SwiftUI

/// A single PaymentMethod model
struct PaymentMethod: Identifiable {
    var id = UUID()
    var name: String
    var details: String
    var isPreferred: Bool = false
}

struct EnhancedPaymentMethodPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // The currently selected PaymentMethod (bound from TradeView)
    @Binding var currentMethod: PaymentMethod
    
    // Callback: when user picks or changes the method
    var onSelect: (PaymentMethod) -> Void
    
    // Our local list of PaymentMethods
    @State private var allMethods: [PaymentMethod] = [
        PaymentMethod(name: "Coinbase", details: "Coinbase Exchange"),
        PaymentMethod(name: "Binance", details: "Binance Exchange"),
        PaymentMethod(name: "Kraken", details: "Kraken Exchange"),
        PaymentMethod(name: "Wallet USD", details: "Local USD wallet"),
        PaymentMethod(name: "Wallet USDT", details: "Local USDT wallet"),
    ]
    
    // For search
    @State private var searchText: String = ""
    
    // For rename
    @State private var renameTarget: PaymentMethod? = nil
    @State private var renameText: String = ""
    @State private var showRenameSheet: Bool = false
    
    // For adding a new payment method
    @State private var showAddSheet: Bool = false
    @State private var newMethodName: String = ""
    @State private var newMethodDetails: String = ""
    
    var filteredMethods: [PaymentMethod] {
        if searchText.isEmpty {
            return allMethods
        }
        return allMethods.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.details.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // SEARCH BAR
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search payment methods", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // LIST OF METHODS
                    List {
                        ForEach(filteredMethods) { method in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    // Show a star if it's the preferred method
                                    HStack(spacing: 4) {
                                        Text(method.name)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                        if method.isPreferred {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                        }
                                    }
                                    Text(method.details)
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                Spacer()
                                // If this method is the currently selected one, show a check
                                if method.id == currentMethod.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.yellow)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Selecting the row
                                currentMethod = method
                                onSelect(method)
                                presentationMode.wrappedValue.dismiss()
                            }
                            // SWIPE ACTIONS (iOS 15+)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteMethod(method)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    renameTarget = method
                                    renameText = method.name
                                    showRenameSheet = true
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.blue)
                                
                                Button {
                                    makePreferred(method)
                                } label: {
                                    Label("Preferred", systemImage: "star")
                                }
                                .tint(.yellow)
                            }
                            // CONTEXT MENU (iOS 13+ fallback)
                            .contextMenu {
                                Button("Make Preferred") {
                                    makePreferred(method)
                                }
                                Button("Rename") {
                                    renameTarget = method
                                    renameText = method.name
                                    showRenameSheet = true
                                }
                                Button(role: .destructive) {
                                    deleteMethod(method)
                                } label: {
                                    Text("Delete")
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // "Close" on the left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.yellow)
                }
                // "Add" on the right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(.yellow)
                }
            }
            // RENAME SHEET
            .sheet(isPresented: $showRenameSheet) {
                if let renameTarget = renameTarget {
                    RenamePaymentMethodView(
                        method: renameTarget,
                        initialText: renameText
                    ) { newName in
                        if let idx = allMethods.firstIndex(where: { $0.id == renameTarget.id }) {
                            allMethods[idx].name = newName
                        }
                    }
                }
            }
            // ADD SHEET
            .sheet(isPresented: $showAddSheet) {
                AddPaymentMethodView(
                    onAdd: { name, details in
                        // Add a new PaymentMethod
                        let newMethod = PaymentMethod(name: name, details: details)
                        allMethods.append(newMethod)
                    }
                )
            }
        }
        .accentColor(.yellow)
    }
    
    // MARK: - Actions
    private func makePreferred(_ method: PaymentMethod) {
        // If you want only one preferred method, set all others to false
        for i in allMethods.indices {
            allMethods[i].isPreferred = false
        }
        if let idx = allMethods.firstIndex(where: { $0.id == method.id }) {
            allMethods[idx].isPreferred = true
        }
    }
    
    private func deleteMethod(_ method: PaymentMethod) {
        if let idx = allMethods.firstIndex(where: { $0.id == method.id }) {
            allMethods.remove(at: idx)
        }
    }
}

/// A small sheet to rename a payment method
struct RenamePaymentMethodView: View {
    let method: PaymentMethod
    @State var text: String
    var onSave: (String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    init(method: PaymentMethod, initialText: String, onSave: @escaping (String) -> Void) {
        self.method = method
        self._text = State(initialValue: initialText)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("New name", text: $text)
            }
            .navigationBarTitle("Rename", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    onSave(text)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

/// A small sheet to add a brand-new PaymentMethod
struct AddPaymentMethodView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var details: String = ""
    
    var onAdd: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment Method Info")) {
                    TextField("Name", text: $name)
                    TextField("Details", text: $details)
                }
            }
            .navigationBarTitle("Add Method", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    // Call the callback
                    onAdd(name, details)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
