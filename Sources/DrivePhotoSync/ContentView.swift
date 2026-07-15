import SwiftUI
import GoogleSignIn

struct ContentView: View {
    @StateObject private var auth = GoogleAuthService.shared
    @AppStorage("selectedFolderId") private var selectedFolderId: String = ""
    @AppStorage("selectedFolderName") private var selectedFolderName: String = ""

    @State private var accessToken: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if auth.currentUser == nil {
                    signedOutView
                } else if let accessToken {
                    signedInView(accessToken: accessToken)
                } else {
                    ProgressView("Обновление токена…")
                }
            }
            .alert("Ошибка", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            auth.restorePreviousSignIn()
        }
        .task(id: auth.currentUser?.userID) {
            if auth.currentUser != nil {
                await refreshToken()
            }
        }
    }

    private var signedOutView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
            Text("Drive Photo Sync")
                .font(.title2)
            Button("Войти через Google") {
                signIn()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func signedInView(accessToken: String) -> some View {
        VStack(spacing: 0) {
            if !selectedFolderId.isEmpty {
                VStack(spacing: 4) {
                    Text("Синхронизируемая папка")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(selectedFolderName)
                        .font(.headline)
                }
                .padding()
            }
            FolderBrowserView(
                folderId: "root",
                folderName: "Мой диск",
                accessToken: accessToken
            ) { id, name in
                selectedFolderId = id
                selectedFolderName = name
            }
        }
    }

    private func signIn() {
        guard let rootVC = UIApplication.shared.rootViewController else { return }
        Task {
            do {
                try await auth.signIn(presenting: rootVC)
                await refreshToken()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func refreshToken() async {
        do {
            accessToken = try await auth.accessToken()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
