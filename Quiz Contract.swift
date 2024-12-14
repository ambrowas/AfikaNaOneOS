import Foundation

/// Represents a quiz question with associated options and the correct answer.
struct QuizQuestion: Identifiable, Codable {
    var id: String // Maps to "Question Number"
    var category: String // Maps to "Category"
    var question: String // Maps to "Question"
    var options: [String: String] // Maps to "Options"
    var answer: String // Maps to "Correct Answer"

    enum CodingKeys: String, CodingKey {
        case id = "Question Number"
        case category = "Category"
        case question = "Question"
        case options = "Options"
        case answer = "Correct Answer"
    }

    /// Computes the key of the correct answer within the options dictionary.
    var correctAnswerKey: String? {
        options.first { $0.value.uppercased() == answer.uppercased() }?.key
    }

    /// Shuffles the options dictionary while maintaining the key-value relationships.
    mutating func shuffleOptions() {
        options = Dictionary(uniqueKeysWithValues: options.shuffled())
    }

    /// Mock initializer for testing purposes.
    init(id: String, category: String, question: String, options: [String: String], answer: String) {
        self.id = id
        self.category = category
        self.question = question
        self.options = options
        self.answer = answer
    }
}
