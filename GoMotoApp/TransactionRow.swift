//
//  TransactionRow.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//

import SwiftUI

struct TransactionRow: View {
    let transaction: AppTransaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.description)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(transaction.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(transaction.isCredit ? "+" : "-")$\(String(format: "%.2f", transaction.amount))")
                    .font(.headline)
                    .foregroundColor(transaction.isCredit ? .green : .red)
                
                Text("Admin Fee: $\(String(format: "%.2f", transaction.adminFee))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Driver Earnings: $\(String(format: "%.2f", transaction.driverEarnings))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}
/*import SwiftUI

struct TransactionRow: View {
    let transaction: AppTransaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.description)
                    .font(.headline)
                Text(transaction.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("$\(transaction.amount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(transaction.isCredit ? .green : .red)
                
                Text("Admin Fee: $\(transaction.adminFee, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Driver Earnings: $\(transaction.driverEarnings, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}
*/
