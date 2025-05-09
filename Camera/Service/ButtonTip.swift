//
//  ButtonTip.swift
//  Camera
//
//  Created by Gilang Ramadhan on 08/05/25.
//

import TipKit


struct ButtonTip: Tip {
    var title: Text {
        Text("Tap to start automatic photo capture hands free and hassle-free.")
            .font(.body)
            
    }
    
//    var message: Text? {
//        Text("Tap to start automatic photo capture hands free and hassle-free")
//    }
    
    var options: [TipOption] { [
        Tips.MaxDisplayCount(1),
        Tips.IgnoresDisplayFrequency(true)
    ] }
}


