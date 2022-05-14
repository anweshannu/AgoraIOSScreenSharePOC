//
//  ViewController.swift
//  ScreenSharePOC
//
//  Created by Anwesh M on 14/05/22.
//

import UIKit
import ReplayKit

class ViewController: UIViewController {
    
    @IBOutlet weak var screenShareButton: UIButton!
    var rpSystemBroadcastPickerView: RPSystemBroadcastPickerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        prepareSystemBroadcaster()
    }
    
    func prepareSystemBroadcaster() {
        if #available(iOS 12.0, *) {
            let frame = CGRect(x: 0, y:0, width: 60, height: 60)
            let systemBroadcastPicker = RPSystemBroadcastPickerView(frame: frame)
            systemBroadcastPicker.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            if let url = Bundle.main.url(forResource: "ScreenSharePOC-Extension", withExtension: "appex", subdirectory: "PlugIns") {
                if let bundle = Bundle(url: url) {
                    systemBroadcastPicker.preferredExtension = bundle.bundleIdentifier
                }
            }
            
            rpSystemBroadcastPickerView = systemBroadcastPicker
        } else {
            self.showAlert(message: "Minimum support iOS version is 12.0")
        }
        
    }
    
    
    @IBAction func screenShareButtonClick(_ sender: Any) {
        
        if let button = rpSystemBroadcastPickerView?.subviews.first as? UIButton{
            button.sendActions(for: .touchUpInside)
        }
        
        DispatchQueue(label: "ScreenSharePOC").async {
            while true{
                
                sleep(2)
                if UIScreen.main.isCaptured {
                    DispatchQueue.main.async { [weak self] in
                        print("Broadcasting")
                        self?.screenShareButton.setTitle("Stop Sharing", for: .normal)
                    }
                }
                else{
                    DispatchQueue.main.async { [weak self] in
                        print("Not Broadcasting")
                        self?.screenShareButton.setTitle("Share My Screen", for: .normal)
                    }
                }
            }
        }
        
    }
    
    func showAlert(title: String? = nil, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

