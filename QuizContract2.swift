import FirebaseFirestore


// Define a structure specifically for Firestore questions
struct FirestoreQuizQuestion {
    var question: String
    var optionA: String
    var optionB: String
    var optionC: String
    var answer: String
    var category: String
    var imageUrl: String
}
//
//protocol QuizContract2 {
//    func fetchQuestion(completion: @escaping (FirestoreQuizQuestion?) -> Void)
//}
//
//class FirestoreService: QuizContract2 {
//    private let db = Firestore.firestore()
//
//    func fetchQuestion(completion: @escaping (FirestoreQuizQuestion?) -> Void) {
//        db.collection("PREGUNTAS").getDocuments { snapshot, error in
//            if let document = snapshot?.documents.randomElement() {
//                let data = document.data()
//                let question = FirestoreQuizQuestion(
//                    question: data["QUESTION"] as? String ?? "",
//                    optionA: data["OPTION_A"] as? String ?? "",
//                    optionB: data["OPTION_B"] as? String ?? "",
//                    optionC: data["OPTION_C"] as? String ?? "",
//                    answer: data["ANSWER"] as? String ?? "",
//                    category: data["CATEGORY"] as? String ?? "",
//                    imageUrl: data["IMAGE"] as? String ?? ""
//                )
//                completion(question)
//            } else {
//                completion(nil)
//            }
//        }
//    }
//}
