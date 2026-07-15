import Foundation

struct DriveFile: Identifiable, Decodable {
    let id: String
    let name: String
    let mimeType: String

    var isFolder: Bool { mimeType == "application/vnd.google-apps.folder" }
}

private struct DriveFileListResponse: Decodable {
    let files: [DriveFile]
}

enum DriveServiceError: Error {
    case badResponse(statusCode: Int)
}

struct DriveService {
    private let filesEndpoint = URL(string: "https://www.googleapis.com/drive/v3/files")!

    func listChildren(of folderId: String, accessToken: String) async throws -> [DriveFile] {
        var components = URLComponents(url: filesEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: "'\(folderId)' in parents and trashed = false"),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType)"),
            URLQueryItem(name: "pageSize", value: "1000"),
            URLQueryItem(name: "orderBy", value: "folder,name"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw DriveServiceError.badResponse(statusCode: statusCode)
        }
        return try JSONDecoder().decode(DriveFileListResponse.self, from: data).files
    }
}
