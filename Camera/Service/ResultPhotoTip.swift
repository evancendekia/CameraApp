//
//  ResultPhotoTip.swift
//  Camera
//
//  Created by Gilang Ramadhan on 08/05/25.
//

import TipKit


struct ResultPhotoTip: Tip {
    var title: Text{
        Text("Click here ")
    }
    
    var message: Text?{
        Text("to see your result Photo")
    }
    
    var options: [TipOption]{
        [
            Tips.MaxDisplayCount(1),
            Tips.IgnoresDisplayFrequency(true),
        ]
    }
}
