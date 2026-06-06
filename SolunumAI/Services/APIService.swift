import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case noInternet
    case invalidURL
    case serverError(String)
    case decodingFailed
    case audioTooShort
    case audioTooLong
    case audioSilent
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noInternet:           return "İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin."
        case .invalidURL:           return "Geçersiz sunucu adresi. Ayarlardan API adresini kontrol edin."
        case .serverError(let m):  return m
        case .decodingFailed:      return "Sunucu yanıtı işlenemedi. Lütfen tekrar deneyin."
        case .audioTooShort:       return "Ses kaydı çok kısa. En az 2 saniye öksürün."
        case .audioTooLong:        return "Ses kaydı çok uzun. En fazla 10 saniye kaydedebilirsiniz."
        case .audioSilent:         return "Ses kaydı çok sessiz. Mikrofona daha yakın konumlanın."
        case .unknown(let e):      return "Beklenmeyen hata: \(e.localizedDescription)"
        }
    }
}

// MARK: - API Service

final class APIService: ObservableObject {

    static let shared = APIService()

    private var baseURL: String {
        UserDefaults.standard.string(forKey: "api_base_url") ?? "https://tinfoil-oppressor-animating.ngrok-free.dev"
    }

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 60
        cfg.timeoutIntervalForResource = 120
        return URLSession(configuration: cfg)
    }()

    private init() {}

    // MARK: - Health Check

    func checkHealth() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { throw APIError.invalidURL }
        let (_, response) = try await session.data(from: url)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    // MARK: - Analyze

    func analyze(audioURL: URL, request: AnalysisRequest) async throws -> AnalysisResponse {
        guard let url = URL(string: "\(baseURL)/analyze") else { throw APIError.invalidURL }

        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = try buildMultipartBody(boundary: boundary, audioURL: audioURL, request: request)
        urlRequest.httpBody = body

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                throw APIError.noInternet
            }
            throw APIError.unknown(urlError)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.decodingFailed }

        if !(200..<300).contains(http.statusCode) {
            // Try to decode a Turkish error message from the API
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let detail = errorBody["detail"] {
                throw APIError.serverError(detail)
            }
            throw APIError.serverError("Sunucu hatası (HTTP \(http.statusCode)). Lütfen tekrar deneyin.")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AnalysisResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    // MARK: - Multipart body builder

    private func buildMultipartBody(boundary: String, audioURL: URL, request: AnalysisRequest) throws -> Data {
        var body = Data()
        let crlf = "\r\n"

        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\(crlf)")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(crlf)\(crlf)")
            body.append("\(value)\(crlf)")
        }

        // Metadata as JSON string
        appendField("metadata", request.toMetadataJSON())

        // Audio file
        let audioData = try Data(contentsOf: audioURL)
        let filename  = audioURL.lastPathComponent
        let mimeType  = audioURL.pathExtension.lowercased() == "m4a" ? "audio/m4a" : "audio/wav"
        body.append("--\(boundary)\(crlf)")
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\(crlf)")
        body.append("Content-Type: \(mimeType)\(crlf)\(crlf)")
        body.append(audioData)
        body.append(crlf)

        body.append("--\(boundary)--\(crlf)")
        return body
    }
}

// MARK: - Data + string append helper

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
