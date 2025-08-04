import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: DataStore
    @State private var selectedType: EyeDropType = .typeA
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Eye Drop", selection: $selectedType) {
                    ForEach(EyeDropType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                Button(action: { store.addEntry(type: selectedType) }) {
                    Text("Drop!")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                List {
                    ForEach(store.entries) { entry in
                        HStack {
                            Text(entry.type.rawValue)
                                .bold()
                            Spacer()
                            Text(entry.date, style: .date)
                            Text(entry.date, style: .time)
                        }
                    }
                }
            }
            .navigationTitle("EyeDrop Logger")
        }
    }
}

#Preview {
    ContentView().environmentObject(DataStore())
}
