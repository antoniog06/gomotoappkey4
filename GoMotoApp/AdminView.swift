//
//  AdminView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import SwiftUI

struct AdminView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var searchText = ""
    
    

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    dashboardMetrics
                    earningsSummarySection
                    searchBar
                    pendingPayoutsSection
                    transactionHistorySection
                }
                .padding()
            }
            .navigationTitle("Admin Dashboard")
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Action Result"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

// MARK: - 📊 Dashboard Metrics
extension AdminView {
    private var dashboardMetrics: some View {
        HStack(spacing: 20) {
            MetricCard(title: "Total Earnings", value: String(format: "$%.2f", viewModel.totalEarnings))
            MetricCard(title: "Pending Payouts", value: "\($viewModel.pendingPayouts.count)")
            MetricCard(title: "Latest Transaction", value: viewModel.transactionHistory.first?.formattedDate ?? "N/A")
        }
    }
}

// MARK: - 💰 Earnings Summary
extension AdminView {
    private var earningsSummarySection: some View {
        VStack(spacing: 10) {
            Text("Earnings Summary").font(.headline)
            Text("$\(viewModel.totalEarnings, specifier: "%.2f")")
                .font(.title2).bold().foregroundColor(.blue)
            
            Button(action: viewModel.processWeeklyPayouts) {
                Text(viewModel.isProcessingPayouts ? "Processing..." : "Process Weekly Payouts")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isProcessingPayouts ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(viewModel.isProcessingPayouts)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 🔎 Search Bar
extension AdminView {
    private var searchBar: some View {
        TextField("Search Transactions or Payouts", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
    }
}

// MARK: - 📌 Pending Payouts
extension AdminView {
    private var pendingPayoutsSection: some View {
        VStack(alignment: .leading) {
            Text("Pending Payouts").font(.headline)
            if $viewModel.pendingPayouts.isEmpty {
                Text("No pending payouts.").foregroundColor(.gray).font(.subheadline).padding()
            } else {
                List(viewModel.pendingPayouts) { payout in
                    PayoutRow(payout: payout)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
}

// MARK: - 📜 Transaction History
extension AdminView {
    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transaction History").font(.headline)
            
            if viewModel.transactionHistory.isEmpty {
                Text("No transactions available")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding()
            } else {
                List(viewModel.transactionHistory.map { $0 }, id: \.id) { transaction in
                    TransactionRow(transaction: transaction)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .padding()
    }
}

