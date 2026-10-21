import CryptoKit
import Foundation

/// Sign in with Apple nonce helpers, pure so they can be checked without the app.
extension Store {
    static func hashed(_ nonce: String) -> String {
        SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// The raw nonce whose hash Apple signed into this identity token, or nil if none of ours match.
    static func rawNonce(for idToken: String, among issued: [String]) -> String? {
        let parts = idToken.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var b64 = parts[1].replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        b64 += String(repeating: "=", count: (4 - b64.count % 4) % 4)
        guard let data = Data(base64Encoded: b64),
              let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let signed = claims["nonce"] as? String else { return nil }
        return issued.first { hashed($0) == signed }
    }
}
