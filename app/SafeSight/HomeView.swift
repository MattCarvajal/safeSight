//
//  HomeView.swift
//  SafeSight
//
//  Created by Matt Carvajal on 1/27/25.
//

import SwiftUI
import CoreBluetooth

struct Photos: Identifiable {
    let id = UUID()
    let filename: String
}

// Trip Def
struct Trip: Identifiable, Codable {
    let id: Int
    let start_time: String
    let distractions: Int
    let end_time: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "trip_id"
        case start_time, distractions, end_time
    }
}


struct HomeView: View {
    
    // App Version
    @State private var appVersion = "1.0.0.0"
    
    // Global Vars for photo viewing
    @State private var photos: [Photos] = []
    @State private var piAddress = "http://10.42.0.1:8080"
    
    // Selected photo state var
    @State private var selectedPhoto: Photos? = nil
    
    // different tabs
    @State var selectedTab = 2
    
    // piImage from pi
    @State private var piImage: UIImage? = nil
    
    // Total trips and total distractions vars (used for profile stats)
    @AppStorage("totalTrips") private var totalTrips = 1
    @AppStorage("totalDistractions") private var totalDistractions = 5
    
    // timers for auto refersh
    @State private var tripsTimer: Timer?
    @State private var photosTimer: Timer?
    
    // Trip ViewModel instance
    @StateObject private var viewModel = TripViewModel()
    
    // Safety Score calculation
    var safetyScore: Int {
        guard totalTrips > 0 else { return 0 }
        return Int((Double(totalTrips) / Double(max(totalDistractions, 1))) * 100)
    }
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }
    
    var body: some View {
        TabView {
            // Tab 1: Home Screen
            ZStack {
                Color.black.ignoresSafeArea()
                
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
                        
                        // Live Trip Data from Pi
                        if viewModel.trips.isEmpty {
                            Text("No trips recorded yet.")
                                .foregroundColor(.gray)
                                .padding(.top, 10)
                        } else {
                            ForEach(viewModel.trips) { trip in
                                HStack {
                                    Text("#\(trip.id)")
                                        .frame(width: 100, alignment: .leading)
                                    Text("\(trip.distractions)")
                                        .padding(.leading, 80)
                                }
                                .padding(.vertical, 4)
                            }
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
                .onAppear {
                    // Start refreshing trips every 5 seconds
                    tripsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                        Task { await viewModel.fetchTrips() }
                    }
                    // Do one immediate fetch
                    Task { await viewModel.fetchTrips() }
                }
                .onDisappear {
                    tripsTimer?.invalidate()
                    tripsTimer = nil
                }
            }
            .tabItem {
                Image(systemName: "house")
            }
            .tag(0)
            // Auto Refresh Every 5 Seconds
            .task {
                await viewModel.fetchTrips()
                // continuously refresh trips every 5 seconds
                Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                    Task {
                        await viewModel.fetchTrips()
                    }
                }
            }
            
            // Tab 2: Photos
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
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
                            Color.black.ignoresSafeArea()
                            VStack {
                                Spacer()
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
            .tabItem {
                Image(systemName: "camera")
            }
            .tag(1)
            .onAppear {
                // Start refreshing photos every 5 seconds
                photosTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                    Task { await fetchPhotos() }
                }
                Task { await fetchPhotos() }
            }
            .onDisappear {
                photosTimer?.invalidate()
                photosTimer = nil
            }
            
            // Profile
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(alignment: .leading) {
                    Text("Your Driving Profile:")
                        .font(.title)
                        .bold()
                        .foregroundStyle(Color.yellow)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Text("👉Safety Score (Out of 100): \(safetyScore)")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundStyle(Color.white)
                        .padding()
                    
                    if (safetyScore >= 80) {
                        Text("✅ You are a super safe driver! 🚗")
                            .font(.system(size: 20))
                            .bold()
                            .foregroundStyle(Color.green)
                            .padding()
                    } else if (safetyScore >= 50) {
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
            .tabItem {
                Image(systemName: "person.circle")
            }
            .tag(2)
        }
        .tint(.yellow)
    }
    
    // Fetch Photos
    func fetchPhotos() async {
        guard let url = URL(string: "\(piAddress)/photos") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let filenames = dict["photos"] as? [String] {
                DispatchQueue.main.async {
                    self.photos = filenames.map { Photos(filename: $0) }
                }
            }
        }.resume()
    }
    
    // Fetch trips
    class TripViewModel: ObservableObject {
        @Published var trips: [Trip] = []
        private let baseURL = "http://10.42.0.1:8080" // Pi iP
        
        func fetchTrips() async {
            guard let url = URL(string: "\(baseURL)/trips") else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode([Trip].self, from: data)
                self.trips = decoded.reversed()
            } catch {
                print("⚠️ Error fetching trips:", error.localizedDescription)
            }
        }
    }
}

#Preview {
    HomeView()
}
