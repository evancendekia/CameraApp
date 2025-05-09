//
//  StopButtonTip.swift
//  Camera
//
//  Created by Gilang Ramadhan on 08/05/25.
//

import TipKit


struct StopButtonTip: Tip {
    var title: Text {
        Text("Tap to stop automatic photo capture.")
            .font(.body)
    }
    
//    var message: Text? {
//        Text("")
//    }
    
    var options: [ TipOption] {
        [
            Tip.MaxDisplayCount(1),
            Tips.IgnoresDisplayFrequency(true)
        ]
    }
}
