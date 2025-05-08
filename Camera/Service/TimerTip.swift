//
//  TimerTip.swift
//  Camera
//
//  Created by Gilang Ramadhan on 08/05/25.
//

import TipKit

struct TimerTip: Tip {
    var title: Text {
        Text("Auto Capture is only available for 1 hour!")
            .font(.body)
//            .fontWeight(.bold)
//            .frame(width: 200, height: 100)
//            .TextAlignment()
        }
    
//    var message: Text? {
//        Text("")
//    }
    
    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1),
            Tips.IgnoresDisplayFrequency(true)
        ]
    }
}
