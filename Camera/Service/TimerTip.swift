//
//  TimerTip.swift
//  Camera
//
//  Created by Gilang Ramadhan on 08/05/25.
//

import TipKit

struct TimerTip: Tip {
    var title: Text {
        Text("Timer")
    }
    
    var message: Text? {
        Text("Auto Capture is only available for 1 hour!")
    }
    
    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1),
            Tips.IgnoresDisplayFrequency(true)
        ]
    }
}
