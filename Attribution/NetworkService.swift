import Foundation

enum AttributionError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
}

class NetworkService {
    private let baseURL: String
    private let apiKey: String
    
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    func sendEvent(_ event: [String: Any], endpoint: String, completion: @escaping (Result<Bool, AttributionError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("ios-sdk-\(AttributionConfig.version)", forHTTPHeaderField: "X-SDK-Version")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: event)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                completion(.success(true))
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
} 