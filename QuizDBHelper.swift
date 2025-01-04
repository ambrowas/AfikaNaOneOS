import Foundation

class QuizDBHelper {
    static let shared = QuizDBHelper()
    private let jsonFileName = "quiz_questions"
    private var allQuestions: [QuizQuestion] = []
    var shownQuestionIds: Set<String> = []

    private init() {
            print("Initializing QuizDBHelper.")
            debugJSONFile()
            loadQuestionsOnce()
            loadShownQuestionIds()
        }
    private func loadQuestionsOnce() {
           allQuestions = loadQuestionsFromJSON() ?? []
       }
    
    func debugJSONFile() {
        if let url = Bundle.main.url(forResource: "quiz_questions", withExtension: "json") {
            print("JSON file URL: \(url)")
        } else {
            print("Error: JSON file not found in the bundle.")
        }
    }

    func loadQuestionsFromJSON() -> [QuizQuestion]? {
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
            print("❌ Error: \(jsonFileName).json file not found in the app bundle.")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

            // ✅ Decode JSON with the correct format
            let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let jsonQuestions = jsonDictionary else {
                print("❌ Error: JSON format is invalid.")
                return nil
            }

            // ✅ Convert JSON dictionary to QuizQuestion objects
            let questions: [QuizQuestion] = jsonQuestions.compactMap { (key, value) in
                guard let questionData = value as? [String: Any],
                      let question = questionData["question"] as? String,
                      let answer = questionData["answer"] as? String,
                      let options = questionData["options"] as? [String: String],
                      let category = questionData["category"] as? String,
                      let explanation = questionData["explanation"] as? String else {
                    print("⚠️ Skipping invalid question entry: \(key)")
                    return nil
                }

                return QuizQuestion(
                    id: key,  // ✅ Use the key as the ID
                    category: category,
                    question: question,
                    options: options,
                    answer: answer,
                    explanation: explanation  // ✅ Include explanation
                )
            }

            print("✅ Successfully decoded \(questions.count) questions from JSON.")
            return questions
        } catch {
            print("❌ Error decoding JSON: \(error.localizedDescription)")
            return nil
        }
    }


    func getRandomQuestions(count: Int) -> [QuizQuestion]? {
           let availableQuestions = allQuestions.filter { !shownQuestionIds.contains($0.id) }
           print("Available questions before fetching: \(availableQuestions.count)")

           if availableQuestions.count < count {
               print("Warning: Requested \(count) questions, but only \(availableQuestions.count) are available.")
               return nil
           } else {
               let shuffledQuestions = availableQuestions.shuffled().prefix(count).map { question -> QuizQuestion in
                   var shuffledQuestion = question
                   shuffledQuestion.shuffleOptions()
                   return shuffledQuestion
               }
               return Array(shuffledQuestions)
           }
       }

    func loadShownQuestionIds() {
        if let shownIdsData = UserDefaults.standard.data(forKey: "ShownQuestions"),
           let shownIds = try? JSONDecoder().decode(Set<String>.self, from: shownIdsData) {
            shownQuestionIds = shownIds
            print("Loaded previously shown question numbers from UserDefaults: \(shownQuestionIds)")
        } else {
            print("No previously shown question numbers found in UserDefaults or failed to decode.")
        }
    }

    
    func markQuestionsAsShown(with numbers: [String]) {
        shownQuestionIds.formUnion(numbers)
        saveShownQuestionIds()
    }
    
    func saveShownQuestionIds() {
        if let shownIdsData = try? JSONEncoder().encode(shownQuestionIds) {
            UserDefaults.standard.set(shownIdsData, forKey: "ShownQuestions")
            print("Saved shown question numbers to UserDefaults.")
        } else {
            print("Failed to encode shown question numbers.")
        }
    }

    func resetShownQuestions() {
        print("Resetting shown questions. Before reset, shownQuestionIds: \(shownQuestionIds)")
        shownQuestionIds.removeAll()
        UserDefaults.standard.removeObject(forKey: "ShownQuestions")
        if UserDefaults.standard.synchronize() {
            print("UserDefaults successfully removed the shown question numbers.")
        } else {
            print("UserDefaults failed to remove the shown question numbers immediately.")
        }
    }

    func markAllButTenQuestionsAsUsed() {
        guard let questions = loadQuestionsFromJSON(), questions.count > 10 else {
            print("Not enough questions to leave 10 unused.")
            return
        }

        shownQuestionIds.removeAll()

        // Use dropLast(10) to skip the last 10 questions, marking the rest as used
        questions.dropLast(10).forEach { shownQuestionIds.insert($0.id) }
        saveShownQuestionIds()
        print("Marked all but ten questions as used. Used question IDs: \(shownQuestionIds)")
    }
    
    func getNumberOfUnusedQuestions() -> Int {
           guard let questions = loadQuestionsFromJSON() else {
               return 0
           }

           let unusedQuestionsCount = questions.filter { !shownQuestionIds.contains($0.id) }.count
           return unusedQuestionsCount
       }
    
    func printShownQuestionIds() {
        print("Current shownQuestionIds: \(shownQuestionIds)")
    }
}
