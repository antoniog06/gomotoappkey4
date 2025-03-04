//
//  MetricCard.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/21/25.
//


import SwiftUI

struct MetricCard: View {
    var title: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title)
                .bold()
                .foregroundColor(.black)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 4))
        .padding(.horizontal)
    }
}