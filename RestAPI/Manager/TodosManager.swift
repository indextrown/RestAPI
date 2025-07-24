//
//  TodosManager.swift
//  RestAPI
//
//  Created by 김동현 on 7/25/25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
}

final class TodosManager {
    static let shared = TodosManager()
    private init() {}

    private let baseURL = URL(string: "http://index.zapto.org:7000")!
    
    // MARK: - Fetch All Todos as Any
    func fetchTodosAny(completion: @escaping (Result<[[String: Any]], APIError>) -> Void) {
        let url = baseURL.appendingPathComponent("/todos")
        URLSession.shared.dataTask(with: url) { data, _, err in
            if let e = err { return completion(.failure(.requestFailed(e))) }
            guard let d = data else { return completion(.failure(.invalidResponse)) }
            do {
                let json = try JSONSerialization.jsonObject(with: d)
                if let array = json as? [[String: Any]] {
                    completion(.success(array))
                } else {
                    completion(.failure(.decodingError(NSError())))
                }
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }

    // MARK: - Fetch Single Todo as Any
    func fetchTodoAny(id: Int, completion: @escaping (Result<[String: Any], APIError>) -> Void) {
        let url = baseURL.appendingPathComponent("/todos/\(id)")
        URLSession.shared.dataTask(with: url) { data, _, err in
            if let e = err { return completion(.failure(.requestFailed(e))) }
            guard let d = data else { return completion(.failure(.invalidResponse)) }
            do {
                let json = try JSONSerialization.jsonObject(with: d)
                if let dict = json as? [String: Any] {
                    completion(.success(dict))
                } else {
                    completion(.failure(.decodingError(NSError())))
                }
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }

    // MARK: - Create Todo as Any
    func createTodoAny(
        _ body: [String: Any],
        completion: @escaping (Result<[String: Any], APIError>) -> Void
    ) {
        guard let url = URL(string: "/todos", relativeTo: baseURL) else {
            return completion(.failure(.invalidURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return completion(.failure(.decodingError(error)))
        }

        URLSession.shared.dataTask(with: req) { data, _, err in
            if let e = err { return completion(.failure(.requestFailed(e))) }
            guard let d = data else { return completion(.failure(.invalidResponse)) }
            do {
                let json = try JSONSerialization.jsonObject(with: d)
                if let dict = json as? [String: Any] {
                    completion(.success(dict))
                } else {
                    completion(.failure(.decodingError(NSError())))
                }
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }

    // MARK: - Update Todo as Any
    func updateTodoAny(
        id: Int,
        body: [String: Any],
        completion: @escaping (Result<[String: Any], APIError>) -> Void
    ) {
        guard let url = URL(string: "/todos/\(id)", relativeTo: baseURL) else {
            return completion(.failure(.invalidURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return completion(.failure(.decodingError(error)))
        }

        URLSession.shared.dataTask(with: req) { data, _, err in
            if let e = err { return completion(.failure(.requestFailed(e))) }
            guard let d = data else { return completion(.failure(.invalidResponse)) }
            do {
                let json = try JSONSerialization.jsonObject(with: d)
                if let dict = json as? [String: Any] {
                    completion(.success(dict))
                } else {
                    completion(.failure(.decodingError(NSError())))
                }
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }

    // MARK: - Delete Todo as Any
    func deleteTodoAny(id: Int, completion: @escaping (Result<Void, APIError>) -> Void) {
        guard let url = URL(string: "/todos/\(id)", relativeTo: baseURL) else {
            return completion(.failure(.invalidURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: req) { _, _, err in
            if let e = err {
                completion(.failure(.requestFailed(e)))
            } else {
                completion(.success(()))
            }
        }.resume()
    }
}

// MARK: - Codable 제네릭 CRUD
extension TodosManager {
    
    /// GET /{path} → [T]
    func fetchAll<T: Decodable>(
        path: String,
        as type: T.Type,
        completion: @escaping (Result<[T], APIError>) -> Void
    ) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            return completion(.failure(.invalidURL))
        }
        URLSession.shared.dataTask(with: url) { data, _, err in
            if let e = err { return completion(.failure(.requestFailed(e))) }
            guard let d = data else { return completion(.failure(.invalidResponse)) }
            do {
                let items = try JSONDecoder().decode([T].self, from: d)
                completion(.success(items))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    /// GET /{path}/{id} → T
    func fetch<T: Decodable>(
        path: String,
        id: Int,
        as type: T.Type,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        let full = "\(path)/\(id)"
        guard let url = URL(string: full, relativeTo: baseURL) else {
            return completion(.failure(.invalidURL))
        }
        URLSession.shared.dataTask(with: url) { data, _, err in
            if let e = err { return completion(.failure(.requestFailed(e))) }
            guard let d = data else { return completion(.failure(.invalidResponse)) }
            do {
                let item = try JSONDecoder().decode(T.self, from: d)
                completion(.success(item))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    /// POST /{path} with U → V
    func create<U: Encodable, V: Decodable>(
        path: String,
        object: U,
        responseAs type: V.Type,
        completion: @escaping (Result<V, APIError>) -> Void
    ) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            return completion(.failure(.invalidURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONEncoder().encode(object)
        } catch {
            return completion(.failure(.decodingError(error)))
        }
        URLSession.shared.dataTask(with: req) { data, _, err in
            if let e = err { return completion(.failure(.requestFailed(e))) }
            guard let d = data else { return completion(.failure(.invalidResponse)) }
            do {
                let created = try JSONDecoder().decode(V.self, from: d)
                completion(.success(created))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    /// PUT /{path}/{id} with U → V
    func update<U: Encodable, V: Decodable>(
        path: String,
        id: Int,
        object: U,
        responseAs type: V.Type,
        completion: @escaping (Result<V, APIError>) -> Void
    ) {
        let full = "\(path)/\(id)"
        guard let url = URL(string: full, relativeTo: baseURL) else {
            return completion(.failure(.invalidURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONEncoder().encode(object)
        } catch {
            return completion(.failure(.decodingError(error)))
        }
        URLSession.shared.dataTask(with: req) { data, _, err in
            if let e = err { return completion(.failure(.requestFailed(e))) }
            guard let d = data else { return completion(.failure(.invalidResponse)) }
            do {
                let updated = try JSONDecoder().decode(V.self, from: d)
                completion(.success(updated))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    /// DELETE /{path}/{id}
    func delete(
        path: String,
        id: Int,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let full = "\(path)/\(id)"
        guard let url = URL(string: full, relativeTo: baseURL) else {
            return completion(.failure(.invalidURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: req) { _, _, err in
            if let e = err {
                completion(.failure(.requestFailed(e)))
            } else {
                completion(.success(()))
            }
        }.resume()
    }
}
