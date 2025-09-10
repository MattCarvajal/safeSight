//
//  ContentView.swift
//  SafeSight
//
//  Created by Matt Carvajal on 1/23/25.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    @State private var showAlert = false
    @State private var goHome = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                // Import background color here
                Image("road2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea(.all)
                VStack{
                    Spacer()
                    
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    // Text for login
                    Text("Welcome to SafeSight!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button("Connect Your Device"){
                        showAlert = true
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(20)
                    
                    Spacer()
                    
                }
                //foreground color for the text
                .foregroundStyle(.black)
                
            }
            .alert("Check Wi-Fi", isPresented: $showAlert){
                Button("Continue") {
                    goHome = true
                }
                Button("Cancel", role: .cancel){}
            } message: {
                Text("Please make sure you are connected to SafeSight Wi-Fi before continuing")
            }
            .navigationDestination(isPresented: $goHome){
                //HomeView()
                PhotoViewTest()
            }
        }
    
    }
}

#Preview {
    ContentView()
}
