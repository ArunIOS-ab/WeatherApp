//
//  WeatherTool.swift
//  WeatherApp
//
//  Tool definitions the agent can invoke. Each tool declares a JSON Schema
//  description of its parameters so the same registry can be handed to a
//  remote LLM's function-calling API or to Foundation Models' tool support.
//

import Foundation

// MARK: - Tool protocol

/// A single capability the agent can call.
///
/// Conformances must be safe to call concurrently: the agent may run several
/// independent tools in the same task group.
protocol WeatherTool: Sendable {
    /// Stable identifier used in prompts and in tool-call dispatch. Must match
    /// the `name` in `parameters` exactly.
    var name: String { get }

    /// Natural language description shown to the model. This is the only thing
    /// guiding tool selection for an LLM backend, so it should state *when* to
    /// prefer the tool, not only what it does.
    var description: String { get }

    /// JSON Schema for the tool's arguments.
    var parameters: ToolSchema { get }

    /// Executes the tool. Throwing surfaces the error to the agent as an
    /// observation it can reason about and recover from.
    func run(arguments: ToolArguments) async throws -> ToolResult
}

// MARK: - Arguments

/// Decoded tool arguments, with accessors that return defaults rather than
/// trapping. LLMs produce imperfect JSON; an agent should degrade rather than
/// crash when a field is missing or mistyped.
struct ToolArguments: Sendable {
    private let values: [String: JSONValue]

    init(_ values: [String: JSONValue] = [:]) {
        self.values = values
    }

    init(from data: Data) throws {
        let decoded = try JSONDecoder().decode([String: JSONValue].self, from: data)
        self.values = decoded
    }

    subscript(key: String) -> JSONValue? { values[key] }

    func string(_ key: String) -> String? {
        guard case .string(let v) = values[key] else { return nil }
        return v
    }

    func double(_ key: String) -> Double? {
        switch values[key] {
        case .number(let v): return v
        case .string(let v): return Double(v)
        default: return nil
        }
    }

    func int(_ key: String) -> Int? {
        double(key).map { Int($0) }
    }

    func bool(_ key: String, default fallback: Bool = false) -> Bool {
        switch values[key] {
        case .bool(let v): return v
        case .number(let v): return v != 0
        default: return fallback
        }
    }

    func stringArray(_ key: String) -> [String] {
        guard case .array(let v) = values[key] else { return [] }
        return v.compactMap { item in
            if case .string(let s) = item { return s }
            return nil
        }
    }
}

// MARK: - Schema

/// A minimal JSON Schema subset: enough for OpenAI-style function calling and
/// for Foundation Models' `Tool` bridging without pulling in a dependency.
struct ToolSchema: Sendable {
    let properties: [String: Property]
    let required: [String]

    struct Property: Sendable {
        enum ValueType: String, Sendable {
            case string, number, integer, boolean, array, object
        }

        let type: ValueType
        let description: String
        let enumValues: [String]?
        let items: ValueType?

        init(type: ValueType,
             description: String,
             enumValues: [String]? = nil,
             items: ValueType? = nil) {
            self.type = type
            self.description = description
            self.enumValues = enumValues
            self.items = items
        }
    }

    init(properties: [String: Property], required: [String]) {
        self.properties = properties
        self.required = required
    }

    /// Serialises to the `parameters` object expected by OpenAI-compatible
    /// chat completion APIs.
    func jsonDictionary() -> [String: Any] {
        var props: [String: Any] = [:]
        for (name, prop) in properties {
            var entry: [String: Any] = [
                "type": prop.type.rawValue,
                "description": prop.description
            ]
            if let values = prop.enumValues { entry["enum"] = values }
            if let itemType = prop.items { entry["items"] = ["type": itemType.rawValue] }
            props[name] = entry
        }
        return ["type": "object", "properties": props, "required": required]
    }
}

// MARK: - Results

/// Structured tool output. `summary` is what gets fed back to the model as an
/// observation, so it should be self-contained prose or compact JSON.
struct ToolResult: Sendable {
    let summary: String
    let data: JSONValue?

    init(summary: String, data: JSONValue? = nil) {
        self.summary = summary
        self.data = data
    }
}

// MARK: - JSONValue

/// A `Codable` JSON tree. Used both for tool argument decoding and for
/// encoding tool results into LLM payloads.
enum JSONValue: Codable, Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Double.self) {
            self = .number(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([JSONValue].self) {
            self = .array(v)
        } else if let v = try? container.decode([String: JSONValue].self) {
            self = .object(v)
        } else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .number(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }

    // MARK: Convenience accessors

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var numberValue: Double? {
        switch self {
        case .number(let v): return v
        case .string(let v): return Double(v)
        default: return nil
        }
    }

    var arrayValue: [JSONValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    subscript(key: String) -> JSONValue? {
        guard case .object(let v) = self else { return nil }
        return v[key]
    }

    /// Builds a value from any `Encodable`, returning `.null` on failure rather
    /// than throwing, since this is used on presentation paths.
    static func from<T: Encodable>(_ value: T) -> JSONValue {
        guard let data = try? JSONEncoder().encode(value),
              let decoded = try? JSONDecoder().decode(JSONValue.self, from: data)
        else { return .null }
        return decoded
    }
}