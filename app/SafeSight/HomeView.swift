//
//  HomeView.swift
//  SafeSight
//
//  Created by Matt Carvajal on 1/27/25.
//

import SwiftUI
import CoreBluetooth

struct Photos: Identifiable{
    let id = UUID()
    let filename: String
}

struct HomeView: View {
    
    // App Version
    @State private var appVersion = "1.0.0.0"
    
    // Global Vars for photo viewing
    @State private var photos: [Photos] = [] // Array of photo sructs
    @State private var piAddress = "http://10.42.0.1:8080" // Pi's hotspot IP + port
    
    // different tabs
    @State var selectedTab = 2
    
    // piImage from pi
    @State private var piImage: UIImage? = nil
    
    // Total trips and total distractions vars (may keep)
    @AppStorage("totalTrips") private var totalTrips = 1
    @AppStorage("totalDistractions") private var totalDistractions = 5
    
    // Safety Score calculation
    var safetyScore: Int {
        guard totalTrips > 0 else { return 0 } // avoid division by 0
        return Int((Double(totalTrips) / Double(max(totalDistractions, 1))) * 100)
    }
    
    
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
//                    Text("Live Camera Feed:")
//                        .font(.title)
//                        .bold()
//                        .padding(.trailing, 100)
//                    
//                    Spacer()
//                    
//                    
//                    // view images on pi
//                    if let image = piImage {
//                        Image(uiImage: image)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 300)
//                        .cornerRadius(12)
//                        .shadow(radius: 10)
//                    } else {
//                        Text("No image yet")
//                            .foregroundColor(.gray)
//                    }
//                    
//                    Button("Capture from Pi") {
//                        Task{
//                            //await fetchPiImageCapture()
//                            await fetchPhotos()
//                        }
//                    }
//                    .buttonStyle(.plain)
//                    .tint(.yellow)
//                    .padding()
                    
                    // PHOTO GALLERY VIEW
                    ScrollView {
                        Text("Photo Gallery")
                            .font(.title)
                            .bold()
                            .padding(.trailing, 175)
                        LazyVStack {
                            ForEach(photos) { photo in
                                AsyncImage(url: URL(string: "\(piAddress)/photos/\(photo.filename)")) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(10)
                                        .shadow(radius: 4)
                                        .padding()
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                        }
                    }
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
                    //await fetchPiImageCapture() // Auto fetch when tab appears
                    await fetchPhotos()
                }
            }
            
            // tab 3: profile tab
            ZStack{
                Color.black
                    .ignoresSafeArea()
                
                VStack(alignment: .leading){
                    Text("Your Driving Profile:")
                        .font(.title)
                        .bold()
                        .foregroundStyle(Color.yellow)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Display stats
                    Text("👉Safety Score (Out of 100): \(safetyScore)")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundStyle(Color.white)
                        .padding()
                    
                    // Safety scrore checker for status message
                    if (safetyScore >= 80 && safetyScore <= 100){
                        Text("✅ You are a super safe driver! 🚗")
                            .font(.system(size: 20))
                            .bold()
                            .foregroundStyle(Color.green)
                            .padding()
                        
                    } else if (safetyScore >= 50 && safetyScore <= 79){
                        Text("⚠️ You are an OK driver! 🚗")
                            .font(.system(size: 20))
                            .bold()
                            .foregroundStyle(Color.yellow)
                            .padding()
                    } else {
                        Text("🚫 You are a danger on the road! 🚗")
                            .font(.system(size: 20))
                            .bold()
                            .foregroundStyle(Color.red)
                            .padding()
                    }
                    
                    Text("👉Total Trips Taken: \(totalTrips)")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundStyle(Color.white)
                        .padding()
            
                    
                    Text("👉Total Distractions Recorded: \(totalDistractions)")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundStyle(Color.white)
                        .padding()
                    
                    Text("👉App Version: \(appVersion)")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundStyle(Color.white)
                        .padding()
                    
                    Spacer()
                }
            }
            //.foregroundStyle(.yellow)
            .tabItem{
                Image(systemName: "person.circle")
            }
            .tag(2)
            
            
        }
        .tint(.yellow) // selected tab icon color
    }
    
    // fetch image from pi
    func fetchPiImageCapture() async {
        guard let url = URL(string: "\(piAddress)/capture") else { return }
           
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
    
    // Fetch photos function from Pi
        func fetchPhotos() async{
            guard let url = URL(string: "\(piAddress)/photos") else { return } // Link to flask endpoint on Pi
            URLSession.shared.dataTask(with: url) { data, _, _ in // Send network request
                if let data = data,
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let filenames = dict["photos"] as? [String] { // Decode
                    DispatchQueue.main.async { // Update the thread
                        self.photos = filenames.map { Photos(filename: $0) }
                    }
                }
            }.resume()
        }
    
}

#Preview {
    HomeView()
}
