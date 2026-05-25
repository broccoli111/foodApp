import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: KitchenStore
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            Section("Supabase") {
                Text("Backend URL: https://ohjezigyqrhkykbjimgo.supabase.co")
                    .font(.footnote)
                Text("Add your publishable key in SupabaseConfig.plist before live auth.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
            Section("Email auth") {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                Button("Sign in") { Task { await store.signIn(email: email, password: password) } }
                Button("Create account") { Task { await store.signUp(email: email, password: password) } }
                if let message = store.authMessage {
                    Text(message).font(.footnote)
                }
            }
            Section("Stores") {
                ForEach(store.stores) { store in
                    HStack {
                        Text(store.name)
                        Spacer()
                        if store.preferred { Text("Preferred").foregroundStyle(Color.basil) }
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
