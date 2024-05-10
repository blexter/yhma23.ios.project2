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
    @Published var habitsLoaded = false
    
    
    
    func resetStreak (habit : inout Habit) {
        
        if !doneYesterday(habit: habit) && !doneToday(habit: habit) {
            habit.streak = 0
            guard let user = auth.currentUser,
                  let habitId = habit.id
                    
            else {return}
            let habitRef = db.collection("users").document(user.uid).collection("habit").document(habitId)
            
            habitRef.updateData(["streak" : habit.streak]) { error in
                if let error = error {
                    print("error \(error)")
                }
            }
        } else {
            print("nothing to reset \(doneYesterday(habit: habit))")
        }
        
    }
    
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
            
            habitRef.updateData(["done" : FieldValue.arrayUnion([date]), "streak" : habit.streak]) { error in
                if let error = error {
                    print("error \(error)")
                }
            }
            
        }
    }
    
    func doneYesterday(habit : Habit) -> Bool {
        let today = Date()
        var calendar = Calendar.current
        
        if let yesterday = calendar.date(byAdding : .day, value: -1, to: today){
            
            let date = returnDateOnly(date: yesterday)
            print("\(date)")
            for doneDate in habit.done {
                if returnDateOnly(date: doneDate) == date {
                    return true
                }
            }
            return false
        }
        return false
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
    
    func saveHabit(ToDB: String, notificationTime : String) {
        guard let user = auth.currentUser else {return}
        let habitRef = db.collection("users").document(user.uid).collection("habit")
        
        let habit = Habit(habit : ToDB)
        
        var dateCom = DateComponents()
        dateCom.minute = 5
        
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "HH:mm"
        if let customDate = dateFormater.date(from: notificationTime) {
            scheduleOrUpdateNotification(for: habit, reminderTime: customDate, update: false)
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
    
    func scheduleOrUpdateNotification(for habit: Habit, reminderTime : Date, update : Bool) {
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(habit.habit)"
        content.body = "Don't forget to work on your habit: \(habit.habit)"
        content.sound = UNNotificationSound.default
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: habit.reminderId.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Scheduled notification for habit: \(habit.habit), ID: \(habit.reminderId.uuidString)")
            }
        }
    }
    
    func removeNotification(for habitID : String) { //Not in use ATM
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habitID])
    }
    
    func debugRemoveALLNotifications() { //For debuging
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func updateNotification(for habitID: String, newReminderTime: Date) { //Not in use ATM
        removeNotification(for : habitID)
        if let habit = habits.first(where: { $0.id == habitID}) {
            scheduleOrUpdateNotification(for: habit, reminderTime: newReminderTime, update : true)
        }
    }
    
    
    
    func checkNextNotificationTime(for habit: Habit) {  //For debuging of notifications
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            for req in requests {
                if let trigger = req.trigger {
                    print("Trigger for \(req.identifier): \(trigger)")
                } else {
                    print("No trigger found for \(req.identifier)")
                }
            }
            if let request = requests.first(where: { $0.identifier == habit.reminderId.uuidString }) {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    if let nextTriggerDate = Calendar.current.date(byAdding: .day, value: 1, to : trigger.nextTriggerDate() ?? Date()) {
                        print("Next notification is: \(nextTriggerDate)")
                        DispatchQueue.main.async {
                            
                            
                            let alert = UIAlertController(title: "Next notification", message: "Next notification is: \(nextTriggerDate)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            let window = UIApplication.shared.windows.first { $0.isKeyWindow }
                            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
                        }
                    } else {
                        print("Failed to calculate teh next time")
                    }
                } else {
                    print("unsuported trigger")
                }
            } else {
                print("no pending notifications found")
            }
            
            
        }
    }
}
