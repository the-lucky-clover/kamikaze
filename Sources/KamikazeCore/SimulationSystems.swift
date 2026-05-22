import Foundation

public struct DamageState: Codable, Sendable, Equatable {
    public var steeringLoss: Double
    public var visibilityLoss: Double
    public var engineLoss: Double
    public var fuelLeak: Double
    public var stabilityLoss: Double

    public init(
        steeringLoss: Double = 0,
        visibilityLoss: Double = 0,
        engineLoss: Double = 0,
        fuelLeak: Double = 0,
        stabilityLoss: Double = 0
    ) {
        self.steeringLoss = steeringLoss
        self.visibilityLoss = visibilityLoss
        self.engineLoss = engineLoss
        self.fuelLeak = fuelLeak
        self.stabilityLoss = stabilityLoss
    }

    public static let pristine = DamageState()

    public var isCritical: Bool {
        max(steeringLoss, visibilityLoss, engineLoss, fuelLeak, stabilityLoss) > 0.75
    }

    public mutating func applyHit(normalizedSeverity: Double) {
        let severity = clamp(normalizedSeverity, lower: 0.03, upper: 0.35)
        steeringLoss = clamp(steeringLoss + (severity * 0.75), lower: 0, upper: 1)
        visibilityLoss = clamp(visibilityLoss + (severity * 0.45), lower: 0, upper: 1)
        engineLoss = clamp(engineLoss + (severity * 0.65), lower: 0, upper: 1)
        fuelLeak = clamp(fuelLeak + (severity * 0.55), lower: 0, upper: 1)
        stabilityLoss = clamp(stabilityLoss + (severity * 0.8), lower: 0, upper: 1)
    }
}

public struct WeatherProfile: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var displayName: String
    public var visibility: Double
    public var windIntensity: Double
    public var stormIntensity: Double
    public var cloudDensity: Double
    public var oceanRoughness: Double
    public var antiAircraftPressure: Double

    public init(
        id: String,
        displayName: String,
        visibility: Double,
        windIntensity: Double,
        stormIntensity: Double,
        cloudDensity: Double,
        oceanRoughness: Double,
        antiAircraftPressure: Double
    ) {
        self.id = id
        self.displayName = displayName
        self.visibility = visibility
        self.windIntensity = windIntensity
        self.stormIntensity = stormIntensity
        self.cloudDensity = cloudDensity
        self.oceanRoughness = oceanRoughness
        self.antiAircraftPressure = antiAircraftPressure
    }
}

