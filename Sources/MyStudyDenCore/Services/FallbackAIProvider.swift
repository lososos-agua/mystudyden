import Foundation

public struct FallbackAIProvider: AIProvider {
    private let primary: any AIProvider
    private let fallback: any AIProvider

    public init(primary: any AIProvider, fallback: any AIProvider) {
        self.primary = primary
        self.fallback = fallback
    }

    public func generateStudyPacket(from source: StudySource, course: Course) async throws -> StudyPacketDraft {
        do {
            return try await primary.generateStudyPacket(from: source, course: course)
        } catch {
            return try await fallback.generateStudyPacket(from: source, course: course)
        }
    }

    public func generateCourseDigest(course: Course, packets: [StudyPacket]) async throws -> CourseDigestDraft {
        do {
            return try await primary.generateCourseDigest(course: course, packets: packets)
        } catch {
            return try await fallback.generateCourseDigest(course: course, packets: packets)
        }
    }

    public func generateTutorHandoffPrompt(context: TutorHandoffContext) async throws -> String {
        do {
            return try await primary.generateTutorHandoffPrompt(context: context)
        } catch {
            return try await fallback.generateTutorHandoffPrompt(context: context)
        }
    }
}
