//
//  saveTip.swift
//  Camera
//
//  Created by Gilang Ramadhan on 08/05/25.
//

import TipKit

struct SaveTip: Tip {
    var title: Text {
        Text("Save Button")
    }
    
    var message: Text? {
        Text("Tap the save button to save your Photos.")
    }
    
    var options: [TipOption]{
        [
            Tips.MaxDisplayCount(2)
        ]
    }
    
    
}
