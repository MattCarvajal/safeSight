//
//  PhotoView(Test).swift
//  SafeSight
//
//  Created by Matt Carvajal on 9/10/25.
//

// THIS IS A TEST VIEW

import SwiftUI

struct Photo: Identifiable{
    let id = UUID()
    let filename: String
}

struct PhotoViewTest: View {
    
    // Global Vars
    @State private var photos: [Photo] = [] // Array of photo sructs
    @State private var piAddress = "http://10.42.0.1:8080" // Pi's hotspot IP + port
    
    //http://192.168.1.207:8080/photos Laptop address for testing
    
    var body: some View {
        NavigationView {
            ScrollView {
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
            .navigationTitle("Pi Photos")
            .onAppear {
                fetchPhotosView()
            }
        }
    }
    
    // Fetch photos function from pi
    func fetchPhotosView() {
        guard let url = URL(string: "\(piAddress)/photos") else { return } // Link to flask endpoint on Pi
        URLSession.shared.dataTask(with: url) { data, _, _ in // Send network request
            if let data = data,
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let filenames = dict["photos"] as? [String] { // Decode
                DispatchQueue.main.async { // Update the thread
                    self.photos = filenames.map { Photo(filename: $0) }
                }
            }
        }.resume()
    }
}


#Preview{
    PhotoViewTest()
}
