//
//  MyHomeWidgetBundle.swift
//  MyHomeWidget
//
//  Created by Sadaqa Developer on 30/7/2025.
//

import WidgetKit
import SwiftUI

@main
struct MyHomeWidgetBundle: WidgetBundle {
    var body: some Widget {
        MyHomeWidget()
        MyHomeWidgetControl()
        MyHomeWidgetLiveActivity()
    }
}
