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
    @State var newHabit = ""
    @State var signedIn = false
    
    @StateObject var habitViewModel = HabitViewModel()
    
    var body: some View {
        if !signedIn {
            SignInView(signedIn : $signedIn)
        } else {
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
                
            }
            Spacer()
            VStack{
                Button(action : {
                    showingAddAlert = true
                }) {
                    Text("Add")
                }
                
                .alert("Lägg till", isPresented: $showingAddAlert) {
                    TextField("Lägg till", text: $newHabit)
                    Button("Add", action: {
                        habitViewModel.saveHabit(ToDB: newHabit)
                        newHabit = ""
                    })
                }
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
        HStack {
            Text(habit.habit)
            Spacer()
            Button(action: {
                viewModel.done(habit : &habit)
            }) {
                if(viewModel.getDone(habit : habit)) {
                    Image(systemName: "square")
                } else {
                    Image(systemName: "checkmark.square")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
