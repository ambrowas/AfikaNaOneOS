
import Foundation
import FirebaseFirestore

class QuestionII {
    var answer: String
    var category: String
    var image: String
    var number: String
    var optionA: String
    var optionB: String
    var optionC: String
    var questionText: String
    
    // Designated initializer
    init(answer: String, category: String, image: String, number: String, optionA: String, optionB: String, optionC: String, questionText: String) {
        self.answer = answer
        self.category = category
        self.image = image
        self.number = number
        self.optionA = optionA
        self.optionB = optionB
        self.optionC = optionC
        self.questionText = questionText
    }
    
    // Convenience initializer that takes a DocumentSnapshot
    convenience init?(document: DocumentSnapshot) {
        guard let data = document.data() else {
            print("Error: No data found in document snapshot.")
            return nil
        }
        
        guard let answer = data["ANSWER"] as? String,
              let category = data["CATEGORY"] as? String,
              let image = data["IMAGE"] as? String,
              let number = data["NUMBER"] as? String,
              let optionA = data["OPTION_A"] as? String,
              let optionB = data["OPTION_B"] as? String,
              let optionC = data["OPTION_C"] as? String,
              let questionText = data["QUESTION"] as? String else {
            print("Error: Document data doesn't match the expected structure. Document data: \(data)")
            return nil
        }
        
        self.init(answer: answer, category: category, image: image, number: number, optionA: optionA, optionB: optionB, optionC: optionC, questionText: questionText)
    }
}

