//
//  ViewController.swift
//  CyaSend
//
//  Created by roger deutsch on 7/26/22.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate
  {
    
    @IBOutlet var outputMessages : UITextView!
    @IBOutlet var sendDataButton : UIButton!
    var currentPeripheral : CBPeripheral!
    var centralManager : CBCentralManager?
    var dataToSend : String = ""
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
        else {
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
//        textDiagnostics.text += "\(central.description) -- \(error?.localizedDescription)"
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
       
    }
    
    @IBAction func SendKeys(_ sender : UIButton){
        let noClipboard = "No Clipboard Data"
        dataToSend = "\((UIPasteboard.general.string ?? noClipboard))"
        
        if (dataToSend == noClipboard){
            outputMessages.text += "No data to send. Try again!\n"
            return
        }
        outputMessages.text += "\(dataToSend)\n"
        if (currentPeripheral != nil){
            centralManager?.connect(currentPeripheral, options: nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            outputMessages.text += "Error discovering service characteristics: \(error.localizedDescription)\n"
        }
        
        service.characteristics?.forEach({ characteristic in
            if let descriptors = characteristic.descriptors {
                outputMessages.text += "DESCRIPTORS \(descriptors)\n"
            }
            let outString = dataToSend
            var data = outString.data(using: String.Encoding.ascii)
           
            for characteristic in service.characteristics! as [CBCharacteristic]{
                if(characteristic.uuid.uuidString == "FFE1")
                {
                    if (peripheral.state.rawValue == 2){
                        outputMessages.text += "SENDING data\n"
                        peripheral.writeValue(data ?? Data(),
                                          for: characteristic,
                                          type: CBCharacteristicWriteType.withoutResponse)
                    }
                }
                else if (characteristic.uuid.uuidString == "2A19") {
                    outputMessages.text += "writing data...\n"
                    peripheral.writeValue(data ?? Data() ,
                                          for: characteristic,
                                          type: CBCharacteristicWriteType.withoutResponse)
                }
                else{
                    outputMessages.text += "uuid :  \(characteristic.uuid.uuidString)\n"
                }
            }
            outputMessages.text += "CHARACTERISTIC : \(characteristic.uuid.uuidString)\n"
            outputMessages.text += "\(characteristic.properties)\n"
            
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.disconnectFromDevice(peripheral)    })
    }
    
    func disconnectFromDevice (_ peripheral: CBPeripheral ) {
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // We only care about 1 named BLE device
        if (peripheral.name == "cyaBle"){
            currentPeripheral = peripheral
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        textDiagnostics.text += "************************\n"
//        textDiagnostics.text += "Connection complete"
//        textDiagnostics.text += "Peripheral info: \(currentPeripheral)\n"
//
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        centralManager?.stopScan()
            //textDiagnostics.text += "Scan Stopped\n"
        
        //Erase data that we might have
        //data.length = 0
        
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices(nil)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
          
      }

    override func viewDidLoad() {
        super.viewDidLoad()
        // viewDidLoad() runs BEFORE CentralManager initialization
        //Initialize CoreBluetooth Central Manager
            self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    @IBAction func sendKeys(sender: UIButton){
        
       centralManager?.connect(currentPeripheral, options: nil)
    }
}

