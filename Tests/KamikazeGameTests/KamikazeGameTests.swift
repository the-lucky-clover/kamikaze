import Foundation
import Testing
@testable import KamikazeCore
@testable import KamikazeGame

@Suite("Kamikaze gameplay")
struct KamikazeGameTests {
    @Test("player flight advances forward and stays above the ocean")
    func playerFlightAdvances() {
        let mission = ContentLibrary.missions[0]
        let aircraft = ContentLibrary.aircraft.first(where: { $0.id == mission.recommendedAircraftID })!
        var simulation = GameSimulation(mission: mission, selectedAircraft: aircraft)

        let startingPosition = simulation.player.position
        simulation.advance(playerInput: PilotInput(throttle: 0.3, pitch: -10, yaw: 0), deltaTime: 1.5)

        #expect(simulation.player.position.z < startingPosition.z)
        #expect(simulation.player.position.y >= 4)
    }

    @Test("sustained fire can complete the mission")
    func combatCompletesMission() {
        let mission = ContentLibrary.missions[0]
        let aircraft = ContentLibrary.aircraft.first(where: { $0.id == mission.recommendedAircraftID })!
        var simulation = GameSimulation(mission: mission, selectedAircraft: aircraft)

        for _ in 0..<240 where simulation.outcome == .inProgress {
            simulation.advance(playerInput: PilotInput(throttle: 0.15, pitch: 0, yaw: 0, firing: true), deltaTime: 1)
        }

        #expect(simulation.outcome == .success)
        #expect(simulation.snapshot.remainingEnemyCount == 0)
    }

    @Test("successful missions unlock rewards")
    func progressionUnlocksRewards() {
        let mission = ContentLibrary.missions[0]
        var director = MissionDirector()

        director.applyOutcome(.success, for: mission.id)

        #expect(director.progression.completedMissionIDs.contains(mission.id))
        #expect(director.progression.unlockedArchiveEntryIDs.contains(mission.archiveRewardID))
        #expect(director.progression.unlockedAircraftIDs.contains(mission.aircraftRewardID!))
    }

    @Test("damage degrades engine, fuel, and handling")
    func damageDegradesFlight() {
        let mission = ContentLibrary.missions[0]
        let aircraft = ContentLibrary.aircraft.first(where: { $0.id == mission.recommendedAircraftID })!
        var simulation = GameSimulation(mission: mission, selectedAircraft: aircraft)
        let baselineSpeed = simulation.player.speed
        let baselineFuel = simulation.player.fuelRemaining

        simulation.debugApplyDamage(toCombatantID: "player", amount: 40)
        simulation.advance(playerInput: PilotInput(throttle: 0.4, pitch: 1, yaw: 1), deltaTime: 1)

        #expect(simulation.player.damageState.engineLoss > 0)
        #expect(simulation.player.damageState.stabilityLoss > 0)
        #expect(simulation.player.fuelRemaining < baselineFuel)
        #expect(simulation.player.speed < baselineSpeed)
    }

    @Test("mission content is codable for JSON pipelines")
    func missionContentRoundTrips() throws {
        let mission = ContentLibrary.missions[0]
        let data = try JSONEncoder().encode(mission)
        let decoded = try JSONDecoder().decode(MissionDefinition.self, from: data)

        #expect(decoded == mission)
    }
}
