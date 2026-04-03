//
//  RimlyWidgetBundle.swift
//  RimlyWidget
//
//  Created by AFP PAR 58 on 29/03/26.
//

import WidgetKit
import SwiftUI

@main
struct RimlyWidgetBundle: WidgetBundle {
    var body: some Widget {
        RimlyWidget()
        RimlyWidgetControl()
        RimlyWidgetLiveActivity()
    }
}
