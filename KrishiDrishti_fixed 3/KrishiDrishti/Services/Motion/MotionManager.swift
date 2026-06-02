// Services/Motion/MotionManager.swift
// KrishiDrishti — Accesses device accelerometer, gyroscope, and step count data

import CoreMotion
import Combine

protocol MotionManagerProtocol: Sendable {
    var stepCountPublisher: AnyPublisher<Int, Never> { get }
    var motionDataPublisher: AnyPublisher<CMDeviceMotion, Never> { get }
    func startTracking()
    func stopTracking()
}

final class MotionManager: MotionManagerProtocol {
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()

    private let stepCountSubject = CurrentValueSubject<Int, Never>(0)
    private let motionDataSubject = PassthroughSubject<CMDeviceMotion, Never>()

    var stepCountPublisher: AnyPublisher<Int, Never> {
        stepCountSubject.eraseToAnyPublisher()
    }

    var motionDataPublisher: AnyPublisher<CMDeviceMotion, Never> {
        motionDataSubject.eraseToAnyPublisher()
    }

    init() {}

    func startTracking() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                if let motion = motion {
                    self?.motionDataSubject.send(motion)
                }
            }
        }

        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, _ in
                if let steps = data?.numberOfSteps {
                    self?.stepCountSubject.send(steps.intValue)
                }
            }
        }
    }

    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        pedometer.stopUpdates()
    }
}
