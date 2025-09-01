//
//  testView.swift
//  SafeSight
//
//  Created by Matt Carvajal on 1/31/25.
//

import SwiftUI

struct testView: View {
    var fruits = ["Apples", "Bananas", "Oranges"]
    
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            VStack {
                List(fruits, id: \.self){fruit in
                    Text(fruit)
                }
                .scrollContentBackground(.hidden)
                
                Button("TAP ME", action: someFunction)
                    .font(.title)
                    .foregroundStyle(.red)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(20)
                
                
            }
            
            
        }
        
        
        
    }
    
    func someFunction() {
        print("button was pressed")
    }
    
}


#Preview {
    testView()
}
