import Foundation

public enum SampleData {
    public static let course = Course(
        title: "Foundations of Human Learning",
        courseCode: "EDU 201",
        instructor: "Prof. Rivera",
        colorName: "teal",
        personalGoal: "Build a durable study system for the semester."
    )

    public static var source: StudySource {
        StudySource(
            courseID: course.id,
            title: "Week 1 Learning Theories Note",
            type: .personalNote,
            rawText: "Behaviorism focuses on observable behavior and reinforcement. Cognitivism focuses on mental models, memory, and information processing. Constructivism emphasizes learners building meaning through active engagement.",
            intent: .organize
        )
    }
}

