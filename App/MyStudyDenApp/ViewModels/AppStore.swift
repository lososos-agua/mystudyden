import Foundation
import Observation
import MyStudyDenCore

@Observable
final class AppStore {
    var semester: Semester
    var sources: [StudySource]
    var packets: [StudyPacket]
    var tasks: [TaskItem]
    private(set) var generationErrorMessage: String?
    private(set) var lastGenerationStatus: String?

    private let aiProviders: [NamedAIProvider]
    private let persistence: AppStorePersistence?

    init(
        semester: Semester,
        sources: [StudySource] = [],
        packets: [StudyPacket] = [],
        tasks: [TaskItem] = [],
        aiProviders: [NamedAIProvider] = [
            NamedAIProvider(name: "Remote OpenRouter", provider: RemoteAIProvider()),
            NamedAIProvider(name: "Apple Foundation", provider: AppleFoundationAIProvider()),
            NamedAIProvider(name: "Mock", provider: MockAIProvider())
        ],
        persistence: AppStorePersistence? = .live
    ) {
        self.semester = semester
        self.sources = sources
        self.packets = packets
        self.tasks = tasks
        self.aiProviders = aiProviders
        self.persistence = persistence
    }

    var courses: [Course] {
        semester.courses
    }

    var semesterDashboard: SemesterDashboard {
        let unresolvedQuestions = packets.flatMap { packet in
            packet.reviewQuestions.filter { !$0.isResolved }
        }
        let recentPackets = packets.sorted { $0.generatedAt > $1.generatedAt }
        let attentionCourseIDs = Set(
            packets
                .filter { packet in
                    packet.learningState.understanding != .understood
                        || packet.learningState.shouldReviewLater
                        || packet.learningState.shouldAskProfessorOrTA
                }
                .map(\.courseID)
        )

        return SemesterDashboard(
            semester: semester,
            dueSoon: sortedIncompleteTasks(tasks),
            coursesNeedingAttention: courses.filter { attentionCourseIDs.contains($0.id) },
            reviewQueue: unresolvedQuestions,
            recentlyAddedPackets: Array(recentPackets.prefix(5))
        )
    }

    func packets(for course: Course) -> [StudyPacket] {
        packets
            .filter { $0.courseID == course.id }
            .sorted { $0.generatedAt > $1.generatedAt }
    }

    func sources(for course: Course) -> [StudySource] {
        sources
            .filter { $0.courseID == course.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func dashboard(for course: Course) -> CourseDashboard {
        let coursePackets = packets(for: course)
        return CourseDashboard(
            course: course,
            recentPackets: coursePackets,
            upcomingTasks: sortedIncompleteTasks(tasks.filter { $0.courseID == course.id }),
            unresolvedQuestions: coursePackets.flatMap { $0.reviewQuestions.filter { !$0.isResolved } },
            weakConcepts: coursePackets
                .filter { $0.learningState.understanding != .understood || $0.learningState.shouldReviewLater }
                .flatMap(\.keyTerms)
        )
    }

    func clearGenerationError() {
        generationErrorMessage = nil
    }

    func deleteSource(_ source: StudySource) {
        sources.removeAll { $0.id == source.id }
        packets.removeAll { packet in
            packet.sourceIDs.contains(source.id)
        }
        persistCurrentState()
    }

    @MainActor
    func addStudySource(
        title: String,
        type: StudySourceType,
        rawText: String,
        intent: CaptureIntent,
        to course: Course
    ) async {
        let source = StudySource(
            courseID: course.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            rawText: rawText.trimmingCharacters(in: .whitespacesAndNewlines),
            intent: intent
        )

        var providerErrors: [String] = []

        for namedProvider in aiProviders {
            do {
                lastGenerationStatus = "Trying \(namedProvider.name)..."
                let draft = try await namedProvider.provider.generateStudyPacket(from: source, course: course)
                let packet = StudyPacketFactory.makePacket(from: draft, source: source, course: course)
                sources.append(source)
                packets.append(packet)
                generationErrorMessage = nil
                lastGenerationStatus = "Generated with \(namedProvider.name)"
                persistCurrentState()
                return
            } catch {
                let message = "\(namedProvider.name): \(Self.describe(error))"
                providerErrors.append(message)
                lastGenerationStatus = "Failed \(message)"
            }
        }

        generationErrorMessage = "Could not generate a study packet. \(providerErrors.last ?? "Please try again.")"
    }

    private func sortedIncompleteTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks
            .filter { !$0.isComplete }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (lhsDate?, rhsDate?):
                    lhsDate < rhsDate
                case (_?, nil):
                    true
                case (nil, _?):
                    false
                case (nil, nil):
                    lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
            }
    }

    private static func describe(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let errorDescription = localizedError.errorDescription {
            return errorDescription
        }

        return String(describing: error)
    }

    private func persistCurrentState() {
        guard let persistence else {
            return
        }

        do {
            try persistence.save(
                AppStoreSnapshot(
                    semester: semester,
                    sources: sources,
                    packets: packets,
                    tasks: tasks
                )
            )
        } catch {
            lastGenerationStatus = "Save failed: \(Self.describe(error))"
        }
    }
}

struct NamedAIProvider {
    var name: String
    var provider: AIProvider
}

struct AppStoreSnapshot: Codable {
    var semester: Semester
    var sources: [StudySource]
    var packets: [StudyPacket]
    var tasks: [TaskItem]
}

struct AppStorePersistence {
    var fileURL: URL

    static var live: AppStorePersistence {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
            .appendingPathComponent("MyStudyDen", isDirectory: true)

        return AppStorePersistence(fileURL: directory.appendingPathComponent("store.json"))
    }

    func load() throws -> AppStoreSnapshot {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.myStudyDen.decode(AppStoreSnapshot.self, from: data)
    }

    func save(_ snapshot: AppStoreSnapshot) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder.myStudyDen.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }
}

private extension JSONDecoder {
    static var myStudyDen: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension JSONEncoder {
    static var myStudyDen: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension AppStore {
    static func loadPersistedOrPreview() -> AppStore {
        let persistence = AppStorePersistence.live

        do {
            let snapshot = try persistence.load()
            return AppStore(
                semester: snapshot.semester,
                sources: snapshot.sources,
                packets: snapshot.packets,
                tasks: snapshot.tasks,
                persistence: persistence
            )
        } catch {
            return seedStore(persistence: persistence)
        }
    }

    static var preview: AppStore {
        seedStore(persistence: nil)
    }

    private static func seedStore(persistence: AppStorePersistence?) -> AppStore {
        let course = SampleData.course
        let semester = Semester(title: "Fall 2026", courses: [course])
        return AppStore(
            semester: semester,
            tasks: [
                TaskItem(courseID: course.id, title: "Read Week 1 article", kind: .reading),
                TaskItem(courseID: course.id, title: "Draft reflection question", kind: .assignment)
            ],
            persistence: persistence
        )
    }
}
