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
    @State var signedIn = false
    
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
                        
                        .alert("Add new habit", isPresented: $showingAddAlert) {
                            TextField("Habit", text: $newHabit)
                            Button("Add", action: {
                                if newHabit != "" {
                                    habitViewModel.saveHabit(ToDB: newHabit)
                                    newHabit = ""
                                }
                            })
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
                }
                .environmentObject(habitViewModel)
        }
            
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
                //presentationMode.wrappedValue.dismiss()
                isPresented = false
            })
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
        HStack {
            Text(habit.habit)
            Spacer()
            Button(action: {
                viewModel.done(habit : &habit)
            }) {
                if(viewModel.doneToday(habit : habit)) {
                    Image(systemName: "checkmark.square")
                } else {
                    Image(systemName: "square")
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
        //.padding()
    }
}

#Preview {
    ContentView()
}
