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

// Define what a trip is
struct CarTrip: Identifiable {
    let id = UUID()
    let tripNum: Int
    let distractions: Int
}

struct HomeView: View {
    
    // App Version
    @State private var appVersion = "1.0.0.0"
    
    // Global Vars for photo viewing
    @State private var photos: [Photos] = [] // Array of photo sructs
    @State private var piAddress = "http://10.42.0.1:8080" // Pi's hotspot IP + port
    
    // Selected photo state var
    @State private var selectedPhoto: Photos? = nil
    
    // different tabs
    @State var selectedTab = 2
    
    // piImage from pi
    @State private var piImage: UIImage? = nil
    
    // TEST DATA
    @State private var trips: [CarTrip] = [
        CarTrip(tripNum: 1, distractions: 3),
        CarTrip(tripNum: 2, distractions: 5),
        CarTrip(tripNum: 3, distractions: 1),
        CarTrip(tripNum: 4, distractions: 0),
        CarTrip(tripNum: 5, distractions: 2),
        CarTrip(tripNum: 6, distractions: 4),
        CarTrip(tripNum: 7, distractions: 6),
        CarTrip(tripNum: 8, distractions: 3),
        CarTrip(tripNum: 9, distractions: 1),
        CarTrip(tripNum: 10, distractions: 2)
    ]
    
    // Total trips and total distractions vars (may keep)
    @AppStorage("totalTrips") private var totalTrips = 1
    @AppStorage("totalDistractions") private var totalDistractions = 5
    
    // Safety Score calculation
    var safetyScore: Int {
        guard totalTrips > 0 else { return 0 } // avoid division by 0
        return Int((Double(totalTrips) / Double(max(totalDistractions, 1))) * 100)
    }
    
    // initialize the tab bar for light and dark mode so the colors unselected color stays the same
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }
    
    var body: some View {
        TabView{
            // tab 1: home screen
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Text("Driver Report:")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .padding(.bottom, 10)
                    
                    Text("Previous 10 Trips:")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Trip #")
                                .font(.headline)
                                .frame(width: 100, alignment: .leading)
                            Text("Distractions")
                                .font(.headline)
                                .padding(.leading, 80)
                        }
                        .padding(.bottom, 5)
                        
                        Divider().background(Color.yellow)
                        
                        ForEach(trips) { trip in
                            HStack {
                                Text("\(trip.tripNum)")
                                    .frame(width: 100, alignment: .leading)
                                Text("\(trip.distractions)")
                                    .padding(.leading, 80)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.yellow, lineWidth: 1)
                    )
                    
                    Spacer()
                }
                .foregroundColor(.yellow)
                .padding()
                }
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
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
                            .foregroundColor(.yellow)

                        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(photos) { photo in
                                AsyncImage(url: URL(string: "\(piAddress)/photos/\(photo.filename)")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 110, height: 110)
                                        .clipped()
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedPhoto = photo
                                        }
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 110, height: 110)
                                }
                            }
                        }
                        .padding()
                    }
                    .fullScreenCover(item: $selectedPhoto) { photo in
                        ZStack {
                            // Black background behind everything
                            Color.black.ignoresSafeArea()
                            
                            VStack {
                                Spacer()
                                
                                // Center the image vertically
                                AsyncImage(url: URL(string: "\(piAddress)/photos/\(photo.filename)")) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(12)
                                        .shadow(radius: 10)
                                        .padding()
                                } placeholder: {
                                    ProgressView()
                                }
                                
                                Spacer()
                            }
                            
                            // Fixed back button at top-left
                            VStack {
                                HStack {
                                    Button(action: {
                                        selectedPhoto = nil
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.yellow)
                                            .padding(10)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                            .shadow(radius: 5)
                                    }
                                    .padding(.leading, 20)
                                    .padding(.top, 40)
                                    
                                    Spacer()
                                }
                                Spacer()
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
