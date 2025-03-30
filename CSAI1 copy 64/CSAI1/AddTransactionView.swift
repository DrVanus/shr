import SwiftUI

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: PortfolioViewModel
    
    @State private var coinSymbol: String = ""
    @State private var quantity: String = ""
    @State private var pricePerUnit: String = ""
    @State private var isBuy: Bool = true
    @State private var date: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Coin Details")) {
                    TextField("Coin Symbol (e.g. BTC)", text: $coinSymbol)
                }
                
                Section(header: Text("Transaction Details")) {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Price per Unit", text: $pricePerUnit)
                        .keyboardType(.decimalPad)
                    
                    Toggle(isOn: $isBuy) {
                        Text(isBuy ? "Buy" : "Sell")
                    }
                    
                    DatePicker("Transaction Date", selection: $date, displayedComponents: .date)
                }
                
                Button(action: addTransaction) {
                    Text("Add Transaction")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationBarTitle("Add Transaction", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func addTransaction() {
        // Validate numeric input
        guard let qty = Double(quantity),
              let price = Double(pricePerUnit) else {
            // You could display an alert here for invalid input
            return
        }
        
        // Now we can call our custom initializer in ANY order:
        let transaction = Transaction(
            coinSymbol: coinSymbol,
            quantity: qty,
            pricePerUnit: price,
            date: date,
            isBuy: isBuy,
            isManual: true
        )
        
        viewModel.addTransaction(transaction)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionView(viewModel: PortfolioViewModel())
    }
}
