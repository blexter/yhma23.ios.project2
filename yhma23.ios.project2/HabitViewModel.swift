//
//  HabitViewModel.swift
//  yhma23.ios.project2
//
//  Created by Andreas Selguson on 2024-05-03.
//

import Foundation
import Firebase

class HabitViewModel : ObservableObject {
    let db = Firestore.firestore()
    let auth = Auth.auth()
    let dateFormatter = DateFormatter()
    
    
    @Published var habits = [Habit]()
    
    func done(habit : inout Habit) {
        if doneToday(habit: habit) {
        
        } else {
            
            let date = Date()
            habit.done.append(date)
            habit.streak += 1
            
            guard let user = auth.currentUser,
                  let habitId = habit.id
            else {return}
            
            let habitRef = db.collection("users").document(user.uid).collection("habit").document(habitId)
            
            habitRef.updateData(["done" : FieldValue.arrayUnion([date])]) { error in
                if let error = error {
                    print("error \(error)")
                } else {
                    print("all good!")
                }
            }
            let newStreakValue = habit.streak
            habitRef.updateData(["streak" : newStreakValue]) { error in
                if let error = error {
                    print("error \(error)")
                } else {
                    print("all good!")
                }
            }
            
        }
    }
    
    func returnDateOnly(date : Date) -> DateComponents {
        let calendar = Calendar.current
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
    
    func doneToday(habit : Habit) -> Bool {
        let date = returnDateOnly(date: Date())
        for doneDate in habit.done {
            if returnDateOnly(date: doneDate) == date {
                return true
            }
        }
        return false
    }
    
    func remove(index : Int) {
        guard let user = auth.currentUser else {return}
        let habitRef = db.collection("users").document(user.uid).collection("habit")
        
        let habit = habits[index]
        if let id = habit.id {
            habitRef.document(id).delete()
        }
    }
    
    func getFormattedDate() -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = Date()
        return dateFormatter.string(from: date)
    }
    
    func listenToDB() {
        guard let user = auth.currentUser else {return}
        
        let habitRef = db.collection("users").document(user.uid).collection("habit")
        habitRef.addSnapshotListener() {
            
            snapshot, err in
            guard let snapshot = snapshot else {return}
            if let err = err {
                print("error \(err)")
            } else {
                self.habits.removeAll()
                for document in snapshot.documents {
                    do {
                        let habit = try document.data(as : Habit.self)
                        self.habits.append(habit)
                    } catch {
                        print("error read from DB")
                    }
                }
            }
        }
    }
    
    func saveHabit(ToDB: String) {
        guard let user = auth.currentUser else {return}
        let habitRef = db.collection("users").document(user.uid).collection("habit")
        
        let habit = Habit(habit : ToDB)
        do {
            try habitRef.addDocument(from: habit)
        } catch {
            print("Something went wrong when saving to DB")
        }
    }
}
