import SwiftUI

struct FolderBrowserView: View {
    let folderId: String
    let folderName: String
    let accessToken: String
    var onSelect: (String, String) -> Void

    @State private var children: [DriveFile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let driveService = DriveService()

    var body: some View {
        List {
            Section {
                Button {
                    onSelect(folderId, folderName)
                } label: {
                    Label("Выбрать «\(folderName)»", systemImage: "checkmark.circle")
                }
            }

            Section {
                ForEach(children.filter(\.isFolder)) { folder in
                    NavigationLink(folder.name) {
                        FolderBrowserView(
                            folderId: folder.id,
                            folderName: folder.name,
                            accessToken: accessToken,
                            onSelect: onSelect
                        )
                    }
                }
            }
        }
        .navigationTitle(folderName)
        .overlay {
            if isLoading {
                ProgressView()
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
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            children = try await driveService.listChildren(of: folderId, accessToken: accessToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
