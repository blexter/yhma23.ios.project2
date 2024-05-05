//
//  HabitViewModel.swift
//  yhma23.ios.project2
//
//  Created by Andreas Selguson on 2024-05-03.
//

import Foundation
import Firebase
import UIKit
import UserNotifications

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
        
        var habit = Habit(habit : ToDB)
        
        let dateString = "2024-05-05 10:40"
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd HH:mm"
        if let customDate = dateFormater.date(from: dateString) {
            habit.reminder = customDate
            scheduleNotification(for: habit)
        }
        do {
            try habitRef.addDocument(from: habit)
        } catch {
            print("Something went wrong when saving to DB")
        }
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }

    // Schedule notification for a habit with a reminder
    func scheduleNotification(for habit: Habit) {
        guard let reminderDate = habit.reminder else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(habit.habit)"
        content.body = "Don't forget to work on your habit: \(habit.habit)"
        content.sound = UNNotificationSound.default
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        dateComponents.day = Calendar.current.component(.day, from: Date())
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: habit.id ?? UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
