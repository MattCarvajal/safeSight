//
//  ContentView.swift
//  SafeSight
//
//  Created by Matt Carvajal on 1/23/25.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationView{
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
                    
                    NavigationLink(destination: BluetoothView()){
                        //Text("Login with Apple ID")
                        Text("Connect Your Device")
                            .font(.title3)
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
        }
    }
}
    // login function that is going to take apple ID and login
    func login(){
        //isLoggedIn = true
    }

#Preview {
    ContentView()
}
