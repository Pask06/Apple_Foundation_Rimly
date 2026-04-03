//
//  RimlyTimerAttributes.swift
//  Rimly
//
//  Created by AFP PAR 58 on 29/03/26.
//
import Foundation
import ActivityKit

struct RimlyTimerAttributes: ActivityAttributes {
    // I dati dinamici (che cambiano nel tempo, es: il timer)
    public struct ContentState: Codable, Hashable {
        var endTime: Date
        var isPaused: Bool
        var progress: Double
    }

    // I dati statici (che non cambiano, es: il nome della campana)
    var bowlName: String
}
