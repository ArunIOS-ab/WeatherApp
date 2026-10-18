//
//  FoundationModelsAvailability.swift
//  WeatherApp
//
//  Availability shim. The Foundation Models implementation is compiled out
//  entirely when the SDK cannot support it, so callers cannot reference the
//  backend type unconditionally. This enum exists in every build and resolves
//  to the real backend only where that is legal.
//
//  Keeps the call sites clean and always compiling:
//      if let backend = FoundationModelsBackend.makeBackend() { ... }
//
//  GUARD DISCIPLINE
//  The `#if` in `makeBackend` must be IDENTICAL to the one guarding the
//  implementation in FoundationModelsBackend.swift. If this shim's condition
//  were true while the implementation was compiled out, the build would fail
//  with "cannot find 'FoundationModelsSDKBackend' in scope". Change both
//  together, or neither.
//

import Foundation

enum FoundationModelsBackend {

    /// True only when the on-device model exists at runtime: iOS 26+ on an
    /// Apple Intelligence capable device, in a build whose SDK understands the
    /// framework.
    static var isSupported: Bool { makeBackend() != nil }

    /// Returns the on-device backend, or nil when unavailable.
    ///
    /// Gate kept in exact sync with FoundationModelsBackend.swift. Both files
    /// are always in the target, so the two conditions always agree. If they
    /// diverge, this file fails to compile with "cannot find
    /// 'FoundationModelsSDKBackend' in scope".
    static func makeBackend() -> (any AgentReasoningBackend)? {
        #if canImport(FoundationModels) && DEPLOYMENT_TARGET_SUPPORTS_FOUNDATION_MODELS
        if #available(iOS 26.0, macOS 26.0, *) {
            return FoundationModelsSDKBackend()
        }
        return nil
        #else
        return nil
        #endif
    }
}