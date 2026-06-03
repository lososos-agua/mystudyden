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

    private let aiProvider: AIProvider

    init(
        semester: Semester,
        sources: [StudySource] = [],
        packets: [StudyPacket] = [],
        tasks: [TaskItem] = [],
        aiProvider: AIProvider = MockAIProvider()
    ) {
        self.semester = semester
        self.sources = sources
        self.packets = packets
        self.tasks = tasks
        self.aiProvider = aiProvider
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

        do {
            let draft = try await aiProvider.generateStudyPacket(from: source, course: course)
            let packet = StudyPacketFactory.makePacket(from: draft, source: source, course: course)
            sources.append(source)
            packets.append(packet)
            generationErrorMessage = nil
        } catch {
            generationErrorMessage = "Could not generate a study packet. Please try again."
        }
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
}

extension AppStore {
    static var preview: AppStore {
        let course = SampleData.course
        let semester = Semester(title: "Fall 2026", courses: [course])
        return AppStore(
            semester: semester,
            tasks: [
                TaskItem(courseID: course.id, title: "Read Week 1 article", kind: .reading),
                TaskItem(courseID: course.id, title: "Draft reflection question", kind: .assignment)
            ]
        )
    }
}
