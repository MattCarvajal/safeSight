//
//  BluetoothView.swift
//  SafeSight
//
//  Created by Matt Carvajal on 1/29/25.
//

import SwiftUI
import CoreBluetooth


// bluetooth view class for delagate methods
class BluetoothViewModel: NSObject, ObservableObject {
    // central manager
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = [] // list of peripherals
    @Published var peripheralNames: [String] = []
    private var refreshTimer: Timer? // timer var

    override init() {
        super.init()
        // implement deagate methods via central manager
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        startRefreshTimer() // start the refresh timer
    }

    // refresh timer function
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            self?.refreshList()
        }
    }

    // function to refresh the list so it doesn't go forever
    private func refreshList() {
        self.peripheralNames.removeAll()
        self.peripherals.removeAll()
        centralManager?.stopScan()
        centralManager?.scanForPeripherals(withServices: nil)
    }

    deinit {
        refreshTimer?.invalidate() // clean up the timer
    }
}

// delagate functions for bluetooth
extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil) // if BT is on, scan for services
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Get the device name or skip if it is empty or nil
        guard let name = peripheral.name, !name.isEmpty else {
            return // skip unknown devices
        }

        // Add the peripheral if it is not already in the list
        if !peripheralNames.contains(name) {
            self.peripherals.append(peripheral)
            self.peripheralNames.append(name)
        }
    }
}



// bluetooth view SwiftUI
struct BluetoothView: View {
    
    @ObservedObject var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
           ZStack{
               Color.black
                   .ignoresSafeArea()
               
               VStack { // need for the double back button issue
                   List(bluetoothViewModel.peripheralNames, id: \.self) { peripheral in
                       Text(peripheral)
                           .foregroundStyle(.yellow)
                   }
                   .scrollContentBackground(.hidden)
                   .toolbar{
                       ToolbarItem(placement: .principal){
                           Text("Bluetooth Devices:")
                               .font(.largeTitle)
                               .bold()
                               .foregroundColor(.yellow)
                       }
                   }
                   .padding()
                   
                   
                   //temporary next button to go to home screen for testing (need to connect to BT item then go to homescreen after)
                   NavigationLink(destination: HomeView()){
                       Text("Next->")
                   }
               }
           }
            
        
        
        
        
    }
}

#Preview {
    BluetoothView()
}
