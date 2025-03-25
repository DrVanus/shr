//
//  AddHoldingView.swift
//  CSAI1
//
//  Lets the user add a new holding with cost basis, price, etc.
//

import SwiftUI

struct AddHoldingView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var coinName: String = ""
    @State private var coinSymbol: String = ""
    @State private var quantity: String = ""
    @State private var currentPrice: String = ""
    @State private var costBasis: String = ""
    @State private var imageUrl: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Coin Info")) {
                    TextField("Coin Name", text: $coinName)
                    TextField("Coin Symbol", text: $coinSymbol)
                    TextField("Image URL (optional)", text: $imageUrl)
                }
                Section(header: Text("Holding Details")) {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Current Price", text: $currentPrice)
                        .keyboardType(.decimalPad)
                    TextField("Total Cost Basis", text: $costBasis)
                        .keyboardType(.decimalPad)
                }
                Button("Add Holding") {
                    guard let qty = Double(quantity),
                          let price = Double(currentPrice),
                          let basis = Double(costBasis) else {
                        return
                    }
                    let trimmedUrl = imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalUrl = trimmedUrl.isEmpty ? nil : trimmedUrl
                    
                    viewModel.addHolding(
                        coinName: coinName,
                        coinSymbol: coinSymbol,
                        quantity: qty,
                        currentPrice: price,
                        costBasis: basis,
                        imageUrl: finalUrl
                    )
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationBarTitle("Add Holding", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
