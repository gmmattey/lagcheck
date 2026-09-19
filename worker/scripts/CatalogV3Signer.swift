import CryptoKit
import Foundation
import Security

enum SignerError: Error { case invalidArguments, keychain(OSStatus), writeFailed }

let service = "com.buildea.lagcheck.catalog.ed25519.v3"
let account = "publisher"

func keyQuery() -> [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service,
     kSecAttrAccount as String: account]
}

func signingKey() throws -> Curve25519.Signing.PrivateKey {
    var query = keyQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecSuccess, let raw = result as? Data {
        return try Curve25519.Signing.PrivateKey(rawRepresentation: raw)
    }
    guard status == errSecItemNotFound else { throw SignerError.keychain(status) }
    let key = Curve25519.Signing.PrivateKey()
    var add = keyQuery()
    add[kSecValueData as String] = key.rawRepresentation
    add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
    let addStatus = SecItemAdd(add as CFDictionary, nil)
    guard addStatus == errSecSuccess else { throw SignerError.keychain(addStatus) }
    return key
}

let args = CommandLine.arguments
guard args.count == 4 else { throw SignerError.invalidArguments }
let payloadURL = URL(fileURLWithPath: args[1])
let envelopeURL = URL(fileURLWithPath: args[2])
let dates = args[3].split(separator: ",", maxSplits: 1).map(String.init)
guard dates.count == 2, let payload = try? Data(contentsOf: payloadURL),
      let model = try? JSONSerialization.jsonObject(with: payload) as? [String: Any],
      let version = model["catalogVersion"] as? String else { throw SignerError.invalidArguments }
let key = try signingKey()
let envelope: [String: Any] = [
    "schemaVersion": 3, "catalogVersion": version,
    "issuedAt": dates[0], "expiresAt": dates[1], "algorithm": "Ed25519",
    "payloadBase64": payload.base64EncodedString(),
    "signatureBase64": try key.signature(for: payload).base64EncodedString()
]
let data = try JSONSerialization.data(withJSONObject: envelope, options: [.prettyPrinted, .sortedKeys])
try data.write(to: envelopeURL, options: .atomic)
print(key.publicKey.rawRepresentation.base64EncodedString())
