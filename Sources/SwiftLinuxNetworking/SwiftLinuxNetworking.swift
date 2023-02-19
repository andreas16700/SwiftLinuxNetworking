public var versionOfSwiftLinuxnetworking = 0.1
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
//let decoder = JSONDecoder()
//let encoder = JSONEncoder()
/// Defines the possible errors
public enum URLSessionAsyncErrors: Error {
	case invalidUrlResponse, missingResponseData
}

/// An extension that provides async support for fetching a URL
///
/// Needed because the Linux version of Swift does not support async URLSession yet.
public extension URLSession {

	/// A reimplementation of `URLSession.shared.data(from: url)` required for Linux
	///
	/// - Parameter url: The URL for which to load data.
	/// - Returns: Data and response.
	///
	/// - Usage:
	///
	///     let (data, response) = try await URLSession.shared.asyncData(from: url)
	func asyncData(from url: URL) async throws -> (Data, URLResponse) {
		return try await withCheckedThrowingContinuation { continuation in
			let task = URLSession.shared.dataTask(with: url) { data, response, error in
				fulfillContinuationFromCompletionHandler(continuation: continuation, data: data, response: response, error: error)
			}
			task.resume()
		}
	}
	func asyncData(with request: URLRequest)async throws -> (Data, URLResponse){
		return try await withCheckedThrowingContinuation { continuation in
			let task = URLSession.shared.dataTask(with: request) { data, response, error in
				fulfillContinuationFromCompletionHandler(continuation: continuation, data: data, response: response, error: error)
			}
			task.resume()
		}
	}
}
func fulfillContinuationFromCompletionHandler(continuation: CheckedContinuation<(Data,URLResponse),Error>, data: Data?, response: URLResponse?, error: Error?){
	if let error = error {
		continuation.resume(throwing: error)
		return
	}
	guard let response = response as? HTTPURLResponse else {
		continuation.resume(throwing: URLSessionAsyncErrors.invalidUrlResponse)
		return
	}
	guard let data = data else {
		continuation.resume(throwing: URLSessionAsyncErrors.missingResponseData)
		return
	}
	continuation.resume(returning: (data, response))
}

extension CodingKey{
	var asString: String{
		if let int = intValue{
			return "int: \(int)"
		}else{
			return stringValue
		}
	}
}
public func jsonString(data: Data)->String?{
	return String(data: data, encoding: .utf8)
}
public func reportError(title: String, _ error: Error, jsonData: Data? = nil){
	var msg: String?
	if let dec = error as? DecodingError{
		var title: String
		var theContext: DecodingError.Context?

		switch dec {
		case .typeMismatch(let any, let context):
			title="Type mismatch for \(any)"
			theContext=context
		case .valueNotFound(let any, let context):
			title="Value not found for \(any)"
			theContext=context
		case .keyNotFound(let codingKey, let context):
			title="Key not found for \(codingKey.asString)"
			theContext=context
		case .dataCorrupted(let context):
			title="Data corrupted"
			theContext=context
		@unknown default:
			title = "Unknown error"
		}
		if let context=theContext{
			let description = context.debugDescription
			let path = context.codingPath.map{$0.asString}.joined(separator: ":")
			let dataString = jsonData != nil ? jsonString(data: jsonData!) : nil
			msg = [
				title,
				description,
				"path: "+path,
				"data: "+(dataString ?? "non utf8!")
			].joined(separator: ". ")
		}

	}
	print("Error!"+title+"\n"+(msg ?? "non-decoding error: \(error)"))
}
