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
    
    // piImage from pi
    @State private var piImage: UIImage? = nil
    
    
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
                    
                    
                    // view images on pi
                    if let image = piImage {
                        Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    } else {
                        Text("No image yet")
                            .foregroundColor(.gray)
                    }
                    
                    Button("Capture from Pi") {
                        Task{
                            await fetchPiImage()
                        }
                    }
                    .buttonStyle(.plain)
                    .tint(.yellow)
                    .padding()
                        
                }
            }
            .foregroundStyle(.yellow)
            .tabItem{
                Image(systemName: "camera")
            }
            .tag(1)
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // wait for camera to init
                    await fetchPiImage() // Auto fetch when tab appears
                }
            }
            
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
    
    // fetch image from pi
    func fetchPiImage() async {
        guard let url = URL(string: "http://10.42.0.1:8080/capture") else { return }
           
           do {
               // Fetch data asynchronously
               let (data, _) = try await URLSession.shared.data(from: url)
               if let image = UIImage(data: data) {
                   // Update UI on main thread
                   await MainActor.run {
                       self.piImage = image
                   }
               }
           } catch {
               print("Error fetching image:", error)
           }
    }
}

#Preview {
    HomeView()
}
