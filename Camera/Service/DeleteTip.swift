//
//  deleteTip.swift
//  Camera
//
//  Created by Gilang Ramadhan on 08/05/25.
//

import TipKit


struct DeleteTip: Tip {
    var title: Text {
        Text("Tap the delete button to remove photo.")
            .font(.body)
            
    }
//    
//    var message: Text? {
//        Text("Tap the delete button to remove photo.")
//    }
    
    var options: [TipOption]{
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}
