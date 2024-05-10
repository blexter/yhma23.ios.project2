//
//  Habit.swift
//  yhma23.ios.project2
//
//  Created by Andreas Selguson on 2024-05-03.
//

import Foundation
import FirebaseFirestoreSwift

struct Habit : Codable, Identifiable, Equatable {
    @DocumentID var id : String?
    var habit : String
    var done : [Date] = []
    var streak : Int = 0
    var reminderId : UUID = UUID()
}
