import Foundation
import GoogleSignIn

enum GoogleAuthError: Error {
    case notSignedIn
    case noResult
}

@MainActor
final class GoogleAuthService: ObservableObject {
    static let shared = GoogleAuthService()

    static let driveReadonlyScope = "https://www.googleapis.com/auth/drive.readonly"

    @Published private(set) var currentUser: GIDGoogleUser?

    private init() {}

    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, _ in
            self?.currentUser = user
        }
    }

    func signIn(presenting viewController: UIViewController) async throws {
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
            GIDSignIn.sharedInstance.signIn(
                withPresenting: viewController,
                hint: nil,
                additionalScopes: [Self.driveReadonlyScope]
            ) { signInResult, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let signInResult {
                    continuation.resume(returning: signInResult)
                } else {
                    continuation.resume(throwing: GoogleAuthError.noResult)
                }
            }
        }
        currentUser = result.user
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
    }

    /// Access token valid for calling the Drive API, refreshing first if needed.
    func accessToken() async throws -> String {
        guard let user = currentUser else { throw GoogleAuthError.notSignedIn }
        let refreshed = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDGoogleUser, Error>) in
            user.refreshTokensIfNeeded { user, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let user {
                    continuation.resume(returning: user)
                } else {
                    continuation.resume(throwing: GoogleAuthError.noResult)
                }
            }
        }
        currentUser = refreshed
        return refreshed.accessToken.tokenString
    }
}
