//
//  Int+MakeMTLBuffer.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 16/1/22.
//

import Foundation
import Metal

extension Int {
    func makeBuffer(
        for device: MTLDevice,
        options: MTLResourceOptions = .storageModeShared
    ) -> MTLBuffer? {
        var value = self
        return withUnsafeBytes(of: &value) { bufferPointer -> MTLBuffer? in
            guard let baseAddress = bufferPointer.baseAddress else { return nil }
            return device.makeBuffer(
                bytes: baseAddress,
                length: bufferPointer.count,
                options: options
            )
        }
    }
}

extension UInt {
    func makeBuffer(
        for device: MTLDevice,
        options: MTLResourceOptions = .storageModeShared
    ) -> MTLBuffer? {
        var value = self
        return withUnsafeBytes(of: &value) { bufferPointer -> MTLBuffer? in
            guard let baseAddress = bufferPointer.baseAddress else { return nil }
            return device.makeBuffer(
                bytes: baseAddress,
                length: bufferPointer.count,
                options: options
            )
        }
    }
}

extension UInt32 {
    func makeBuffer(
        for device: MTLDevice,
        options: MTLResourceOptions = .storageModeShared
    ) -> MTLBuffer? {
        var value = self
        return withUnsafeBytes(of: &value) { bufferPointer -> MTLBuffer? in
            guard let baseAddress = bufferPointer.baseAddress else { return nil }
            return device.makeBuffer(
                bytes: baseAddress,
                length: bufferPointer.count,
                options: options
            )
        }
    }
}

extension ContiguousArray {
    func makeBuffer(
        for device: MTLDevice,
        options: MTLResourceOptions = .storageModeShared
    ) -> MTLBuffer? {
        self.withUnsafeBytes { bufferPointer -> MTLBuffer? in
            guard let baseAddress = bufferPointer.baseAddress else { return nil }
            return device.makeBuffer(
                bytes: baseAddress,
                length: bufferPointer.count,
                options: .storageModeShared
            )
        }
    }
}

extension Float {
    func makeBuffer(
        for device: MTLDevice,
        options: MTLResourceOptions = .storageModeShared
    ) -> MTLBuffer? {
        var value = self
        return withUnsafeBytes(of: &value) { bufferPointer -> MTLBuffer? in
            guard let baseAddress = bufferPointer.baseAddress else { return nil }
            return device.makeBuffer(
                bytes: baseAddress,
                length: bufferPointer.count,
                options: options
            )
        }
    }
}
