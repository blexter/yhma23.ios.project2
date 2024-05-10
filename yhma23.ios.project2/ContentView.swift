//
//  ContentView.swift
//  yhma23.ios.project2
//
//  Created by Andreas Selguson on 2024-04-25.
//

import SwiftUI
import Firebase

struct ContentView: View {
    
    @State var showingAddAlert = false
    @State var showStatistics = false
    @State var newHabit = ""
    @State var reminderTime = Date()
    @State var signedIn = false
    @State private var loaded : Bool = false
    
    @StateObject var habitViewModel = HabitViewModel()
    
    var body: some View {
        if !signedIn {
            SignInView(signedIn : $signedIn)
        } else {
            ZStack {
                VStack {
                    List {
                        ForEach(habitViewModel.habits.indices, id: \.self) { index in
                            RowView(habit: $habitViewModel.habits[index], viewModel : habitViewModel)
                        }
                        .onDelete() { indexSet in
                            for index in indexSet {
                                habitViewModel.remove(index:index)
                            }
                        }
                    }
                    
                    
                    HStack {
                        Button(action : {
                            showingAddAlert = true
                        }) {
                            Text("Add")
                        }
                        .sheet(isPresented: $showingAddAlert) {
                            AddHabitAlert(isPresented: $showingAddAlert)
                                .environmentObject(habitViewModel)
                            
                        }
                        
                        Spacer()
                        Button(action : {
                            showStatistics.toggle()
                        }) {
                            Text("Statistics")
                        }
                    }
                    .padding()
                }
                if showStatistics {
                    Color.white.opacity(1).edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    StatisticView(isPresented: $showStatistics).frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
                }
            }
            
            .onAppear{
                habitViewModel.listenToDB()
                habitViewModel.requestNotificationAuthorization()
                //habitViewModel.debugRemoveALLNotifications() //For debugging
            }
            .environmentObject(habitViewModel)
        }
        
    }
    
    func createAlert() -> Alert {
        let alert = UIAlertController(title: "Add new habit", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Habit"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            if let habitName = alert.textFields?.first?.text, !habitName.isEmpty {
                let dateFormater = DateFormatter()
                dateFormater.dateFormat = "HH:mm"
                let remindTime = dateFormater.string(from: self.reminderTime)
                self.habitViewModel.saveHabit(ToDB: newHabit, notificationTime: remindTime)
                self.newHabit = ""
            }
        }))
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addAction(UIAction(handler: { _ in
            self.dateChanged(datePicker)
        }), for: .valueChanged)
        
        alert.view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 20).isActive = true
        datePicker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -20).isActive = true
        datePicker.topAnchor.constraint(equalTo: alert.textFields!.first!.bottomAnchor, constant: 10).isActive = true
        
        return Alert(title: Text(""), message: Text(""), dismissButton: .none)
    }
    
    func dateChanged(_ sender: UIDatePicker) {
        self.reminderTime = sender.date
    }
    
    
}


struct StatisticView : View {
    @Binding var isPresented : Bool
    @EnvironmentObject var viewModel : HabitViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(viewModel.habits) { habit in
                        RowViewStatistics(habit: habit, viewModel: viewModel)
                    }
                }
            }
            .navigationBarItems(leading: Button("Back") {
                isPresented = false
            })
        }
        .onAppear {
            for index in viewModel.habits.indices {
                viewModel.resetStreak(habit: &viewModel.habits[index])
            }
        }
    }
    
}

struct SignInView : View {
    @Binding var signedIn : Bool
    var auth = Auth.auth()
    var body : some View {
        Button(action: {
            auth.signInAnonymously { result, error in
                if let error = error {
                    print("error logging in \(error)")
                } else {
                    signedIn = true
                }
            }
        }, label: {
            Text("Log in")
        })
    }
}

struct RowView : View {
    @Binding var habit : Habit
    let viewModel : HabitViewModel
    
    var body : some View {
        Button(action: {
            //viewModel.checkNextNotificationTime(for: habit) //For debuging of notifications
        }) {
            HStack {
                Text(habit.habit)
                Spacer()
                if(viewModel.doneToday(habit : habit)) {
                    Image(systemName: "checkmark.square")
                        .onTapGesture {
                            viewModel.done(habit : &habit)
                        }
                } else {
                    Image(systemName: "square")
                        .onTapGesture {
                            viewModel.done(habit : &habit)
                        }
                }
            }
        }
    }
}

struct RowViewStatistics : View {
    let habit : Habit
    let viewModel : HabitViewModel
    
    var body : some View {
        VStack(alignment: .leading) {
            HStack {Text(habit.habit).font(.headline)
                Spacer()
                Text("\(habit.streak) times in row!")
                    .padding()
            }
            
            if !habit.done.isEmpty {
                ForEach(habit.done, id: \.self) { doneDate in
                    Text(DateFormatter.localizedString(from: doneDate, dateStyle: .medium, timeStyle: .none))
                }
            } else {
                Text("No dates recorded - come on! Lets start!")
            }
        }
    }
}

struct AddHabitAlert: View {
    @Binding var isPresented: Bool
    @State private var habitName = ""
    @State private var reminderTime = Date()
    
    @EnvironmentObject var habitViewModel: HabitViewModel
    
    var body: some View {
        VStack {
            TextField("Habit", text: $habitName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            DatePicker("Reminder", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .padding()
                
                Spacer()
                
                Button("Add") {
                    saveHabit()
                }
                .padding()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
    
    func saveHabit() {
        guard !habitName.isEmpty else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let remindTime = dateFormatter.string(from: reminderTime)
        
        habitViewModel.saveHabit(ToDB: habitName, notificationTime: remindTime)
        habitName = ""
        isPresented = false
    }
}


#Preview {
    ContentView()
}
