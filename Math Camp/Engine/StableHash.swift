//
//  StableHash.swift
//  Math Camp
//

import Foundation

/// A hash that is identical on every launch and device.
/// (`hashValue` / `Hasher` are randomly seeded per process and must never be used for seeds.)
nonisolated enum StableHash {
    /// FNV-1a, 64-bit.
    static func fnv1a64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }

    /// Seed of one task. The `v1` suffix is the generator version: bump it only if you
    /// intentionally want every task to change.
    static func seed(categoryID: String, taskNumber: Int) -> UInt64 {
        fnv1a64("\(categoryID)#\(taskNumber)#v1")
    }
}
