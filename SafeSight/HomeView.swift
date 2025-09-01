//
//  HomeView.swift
//  SafeSight
//
//  Created by Matt Carvajal on 1/27/25.
//

import SwiftUI
import CoreBluetooth

struct HomeView: View {
    
    // different tabs
    @State var selectedTab = 2
    
    
    // car trips
    struct CarTrips: Identifiable{
        let id = UUID() //unique ID that pairs the two vars together
        let tripNum: String
        let distractions: String
    }
    
    /*@State private var trips: [CarTrips] = [
        CarTrips(tripNum: "1", distractions: "2"),
        CarTrips(tripNum: "1", distractions: "2"),
        CarTrips(tripNum: "1", distractions: "2"),
        CarTrips(tripNum: "1", distractions: "2")
        ]
     */
    
    // initialize the tab bar for light and dark mode so the colors unselected color stays the same
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }
    
    var body: some View {
        TabView{
            // tab 1: home screen
            ZStack{
                Color.black
                    .ignoresSafeArea()
                VStack{
                    Text("Driver Report:") //driver report text and style
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                    
                        .padding(.bottom, 10)
                    
                    Text("Previous 10 Trips:")
                     .font(.title)
                     .fontWeight(.bold)
                     .padding(.trailing, 85)
                     
                     /* Table(trips) {
                     TableColumn("Trip Number", value: \.tripNum)
                     TableColumn("Distractions", value: \.distractions)
                     }
                     .padding()
                     .scaledToFit()
                     
                     
                    */
                    
                    
                    Spacer()
                    
                }
            }
            .foregroundStyle(.yellow)
            .tabItem{
                Image(systemName: "house")
            }
            .tag(0)
            
            // tab 2
            ZStack{
                Color.black
                    .ignoresSafeArea()
                
                // live camera tab
                VStack{
                    Text("Live Camera Feed:")
                        .font(.title)
                        .bold()
                        .padding(.trailing, 100)
                    
                    Spacer()
                }
            }
            .foregroundStyle(.yellow)
            .tabItem{
                Image(systemName: "camera")
            }
            .tag(1)
            
            // tab 3: profile tab
            ZStack{
                Color.black
                    .ignoresSafeArea()
                
                VStack{
                    Text("Your Profile:")
                        .font(.title)
                        .bold()
                        .padding(.trailing, 200)
                    
                    Spacer()
                }
            }
            .foregroundStyle(.yellow)
            .tabItem{
                Image(systemName: "person.circle")
            }
            .tag(2)
            
            
        }
        .tint(.yellow) // selected tab icon color
        
    
            
    }
}

#Preview {
    HomeView()
}
