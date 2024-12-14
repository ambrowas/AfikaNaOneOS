
import Foundation
import SQLite3

class DatabaseManager {
    var db: OpaquePointer?
    private var fileURL: URL // Add this property
    
    static let shared = DatabaseManager()
   init() {
           // Initialize the fileURL
           self.fileURL = try! FileManager.default
               .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
               .appendingPathComponent("PreguntasDatabase.sqlite")
       }
 
    
    func openDatabase() -> Bool {
        print("openDatabase - Attempting to open the database.")
        let fileManager = FileManager.default

        // Ensure the directory exists
        do {
            let appSupportDirectory = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            if !fileManager.fileExists(atPath: appSupportDirectory.path) {
                try fileManager.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            let databasePath = appSupportDirectory.appendingPathComponent("PreguntasDatabase.sqlite")
            self.fileURL = databasePath

            if sqlite3_open(databasePath.path, &db) != SQLITE_OK {
                print("openDatabase - Error opening database: \(String(cString: sqlite3_errmsg(db)))")
                return false
            }
            print("openDatabase - Database opened successfully.")
        } catch {
            print("openDatabase - Error initializing the database directory: \(error.localizedDescription)")
            return false
        }

        // Ensure the Preguntas table is created
        createTable() // Call after confirming the database is open
        return true
    }
    
    func resetDatabase() {
        guard let db = db else { return }
        sqlite3_close(db)
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("resetDatabase - Database file reset successfully.")
        } catch {
            print("resetDatabase - Error resetting database file: \(error)")
        }
    }
    let databaseQueue = DispatchQueue(label: "com.example.databaseQueue")

    func performDatabaseOperation(_ operation: @escaping () -> Void) {
        databaseQueue.async {
            operation()
        }
    }
    
    func createTable() {
    
        print("createTable - Attempting to create the table.")
        let createTableString = """
        CREATE TABLE IF NOT EXISTS Preguntas (
            Id INTEGER PRIMARY KEY AUTOINCREMENT,
            QUESTION TEXT,
            OPTION_A TEXT,
            OPTION_B TEXT,
            OPTION_C TEXT,
            ANSWER TEXT,
            CATEGORY TEXT,
            IMAGE TEXT,
            NUMBER TEXT UNIQUE,
            USED INTEGER DEFAULT 0
        );
        """
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("createTable - Table created successfully.")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("createTable - Could not create table. Error: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("createTable - CREATE TABLE statement could not be prepared. Error: \(errorMessage)")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func insertQuestion(question: QuestionII, completion: @escaping (Bool) -> Void) {
        print("insertQuestion - Attempting to insert \(question.number)")
        guard openDatabase() else {
            print("insertQuestion - Unable to open the database.")
            completion(false)
            return
        }
        
        let insertStatementString = """
        INSERT INTO Preguntas (QUESTION, OPTION_A, OPTION_B, OPTION_C, ANSWER, CATEGORY, IMAGE, NUMBER) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        var insertStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            defer { sqlite3_finalize(insertStatement) }
            // Binding the question properties to the INSERT statement
            sqlite3_bind_text(insertStatement, 1, (question.questionText as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (question.optionA as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, (question.optionB as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, (question.optionC as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 5, (question.answer as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 6, (question.category as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, (question.image as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 8, (question.number as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE
            {
                print("insertQuestion - Successfully inserted question with NUMBER: \(question.number).")
                completion(true)
            } else {
                let errmsg = String(cString: sqlite3_errmsg(db))
                print("insertQuestion - Could not insert question with NUMBER: \(question.number). Error: \(errmsg)")
                completion(false)
            }
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("insertQuestion - INSERT statement could not be prepared for question with NUMBER: \(question.number). Error: \(errmsg)")
            
            
            completion(false)
            
            
        }
        print("insertQuestion - Exited.")
    }
    
    func fetchRandomQuestionFromLocalDatabase() -> QuestionII? {
        print("fetchRandomQuestionFromLocalDatabase - Retrieving a random question from the local database.")
        guard openDatabase() else {
            print("fetchRandomQuestionFromLocalDatabase - Unable to open the database.")
            return nil
        }
        
        let querySQL = """
        SELECT QUESTION, OPTION_A, OPTION_B, OPTION_C, ANSWER, CATEGORY, IMAGE, NUMBER
        FROM Preguntas WHERE Used = 0 ORDER BY RANDOM() LIMIT 1;
        """
        var queryStatement: OpaquePointer?
        var question: QuestionII?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let questionText = String(cString: sqlite3_column_text(queryStatement, 0))
                let optionA = String(cString: sqlite3_column_text(queryStatement, 1))
                let optionB = String(cString: sqlite3_column_text(queryStatement, 2))
                let optionC = String(cString: sqlite3_column_text(queryStatement, 3))
                let answer = String(cString: sqlite3_column_text(queryStatement, 4))
                let category = String(cString: sqlite3_column_text(queryStatement, 5))
                let image = String(cString: sqlite3_column_text(queryStatement, 6))
                let number = String(cString: sqlite3_column_text(queryStatement, 7))
                
                question = QuestionII(
                    answer: answer,
                    category: category,
                    image: image,
                    number: number,
                    optionA: optionA,
                    optionB: optionB,
                    optionC: optionC,
                    questionText: questionText
                )
                print("fetchRandomQuestionFromLocalDatabase - Retrieved question with NUMBER: \(question!.number).")
            } else {
                print("fetchRandomQuestionFromLocalDatabase - No random question could be retrieved.")
            }
            sqlite3_finalize(queryStatement)
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("fetchRandomQuestionFromLocalDatabase - SELECT statement could not be prepared. Error: \(errmsg)")
        }
        
        return question
    }
    
    func countUnusedQuestions() -> Int {
        print("countUnusedQuestions - Counting unused questions in the local database.")
        guard openDatabase() else {
            print("countUnusedQuestions - Unable to open the database.")
            return 0
        }
        
        let queryStatementString = "SELECT COUNT(*) FROM Preguntas WHERE Used = 0;"
        var queryStatement: OpaquePointer?
        var count = 0
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(queryStatement, 0))
                print("countUnusedQuestions - Count of unused questions: \(count).")
            } else {
                print("countUnusedQuestions - Count query did not return any rows, which is unexpected.")
            }
            sqlite3_finalize(queryStatement)
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("countUnusedQuestions - SELECT statement could not be prepared. Error: \(errmsg)")
        }
        return count
    }
    
    func markQuestionAsUsed(questionNumber: String) {
        print("markQuestionAsUsed - Marking question NUMBER: \(questionNumber) as used.")
        guard openDatabase() else {
            print("markQuestionAsUsed - Unable to open the database.")
            return
        }
        let updateStatementString = "UPDATE Preguntas SET Used = 1 WHERE NUMBER = ?;"
        var updateStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(updateStatement, 1, (questionNumber as
                                                   NSString).utf8String, -1, nil)
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("markQuestionAsUsed - Successfully marked question NUMBER: \(questionNumber) as used.")
            } else {
                let errmsg = String(cString: sqlite3_errmsg(db))
                print("markQuestionAsUsed - Could not mark question NUMBER: \(questionNumber) as used. Error: \(errmsg)")
            }
            sqlite3_finalize(updateStatement)
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("markQuestionAsUsed - UPDATE statement could not be prepared. Error: \(errmsg)")
        }
        print("markQuestionAsUsed - Exited.")
    }
    
    func markFortyRandomQuestionsAsUsed() {
        print("markFortyRandomQuestionsAsUsed - Attempting to mark 40 random questions as used.")
        guard openDatabase() else {
            print("markFortyRandomQuestionsAsUsed - Unable to open the database.")
            return
        }
        let updateStatementString = """
                    UPDATE Preguntas
                    SET Used = 1
                    WHERE Id IN (
                        SELECT Id FROM Preguntas
                        WHERE Used = 0
                        ORDER BY RANDOM()
                        LIMIT 40
                    );
                    """
        var updateStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                let affectedRows = sqlite3_changes(db)
                print("markFortyRandomQuestionsAsUsed - Successfully marked \(affectedRows) questions as used.")
            } else {
                let errmsg = String(cString: sqlite3_errmsg(db))
                print("markFortyRandomQuestionsAsUsed - Could not mark 40 random questions as used. Error: \(errmsg)")
            }
            sqlite3_finalize(updateStatement)
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("markFortyRandomQuestionsAsUsed - UPDATE statement could not be prepared. Error: \(errmsg)")
        }
        print("markFortyRandomQuestionsAsUsed - Exited.")
    }
    
    func refreshQuestionsInLocalDatabase(newQuestions: [QuestionII]) {
        print("refreshQuestionsInLocalDatabase - Entered.")
        guard openDatabase() else {
            print("refreshQuestionsInLocalDatabase - Unable to open the database.")
            return
        }
        deleteAllButLastFiveUnusedQuestions()
        var insertedQuestionsCount = 0  // Counter for successful insertions
        let dispatchGroup = DispatchGroup()
        
        for question in newQuestions {
            dispatchGroup.enter()  // Indicate that we are entering the group
            insertQuestion(question: question) { success in
                if success {
                    insertedQuestionsCount += 1
                    print("refreshQuestionsInLocalDatabase - Inserted question NUMBER: \(question.number)")
                } else {
                    print("refreshQuestionsInLocalDatabase - Failed to insert question NUMBER: \(question.number)")
                }
                dispatchGroup.leave()  // Indicate that we are leaving the group
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // This block will be called when all insertions have been completed
            print("refreshQuestionsInLocalDatabase - Completed. Total of \(insertedQuestionsCount) new questions were inserted.")
            // You can place any additional code here that should run after all questions have been inserted
        }
    }
    
    func deleteAllButLastFiveUnusedQuestions(completion: (() -> Void)? = nil) {
        print("deleteAllButLastFiveUnusedQuestions - Entered.")

        guard openDatabase() else {
            print("deleteAllButLastFiveUnusedQuestions - Unable to open the database.")
            completion?()
            return
        }

        // Start the transaction
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)

        var countToDelete = 0
        var totalQuestions = 0
        var unusedQuestions = 0
        var usedQuestions = 0

        // Count the number of used questions to be deleted
        let countToDeleteSQL = "SELECT COUNT(*) FROM Preguntas WHERE Used = 1;"
        var countStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, countToDeleteSQL, -1, &countStmt, nil) == SQLITE_OK {
            if sqlite3_step(countStmt) == SQLITE_ROW {
                countToDelete = Int(sqlite3_column_int(countStmt, 0))
            }
            sqlite3_finalize(countStmt)
        }

        // DELETE all used questions
        let deleteSQL = "DELETE FROM Preguntas WHERE Used = 1;"
        var deleteStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &deleteStmt, nil) == SQLITE_OK {
            if sqlite3_step(deleteStmt) == SQLITE_DONE {
                print("deleteAllButLastFiveUnusedQuestions - Successfully deleted \(countToDelete) used questions.")
            } else {
                print("deleteAllButLastFiveUnusedQuestions - Error executing DELETE statement: \(String(cString: sqlite3_errmsg(db)))")
            }
            sqlite3_finalize(deleteStmt)
        }

        // Count total, unused, and used questions after deletion
        let countAllSQL = "SELECT COUNT(*), SUM(CASE WHEN Used = 0 THEN 1 ELSE 0 END), SUM(CASE WHEN Used = 1 THEN 1 ELSE 0 END) FROM Preguntas;"
        if sqlite3_prepare_v2(db, countAllSQL, -1, &countStmt, nil) == SQLITE_OK {
            if sqlite3_step(countStmt) == SQLITE_ROW {
                totalQuestions = Int(sqlite3_column_int(countStmt, 0))
                unusedQuestions = Int(sqlite3_column_int(countStmt, 1))
                usedQuestions = Int(sqlite3_column_int(countStmt, 2))
            }
            sqlite3_finalize(countStmt)
        }

        // Commit the transaction
        if sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, nil) == SQLITE_OK {
            print("deleteAllButLastFiveUnusedQuestions - TRANSACTION COMMIT successful.")
        } else {
            print("deleteAllButLastFiveUnusedQuestions - TRANSACTION COMMIT failed: \(String(cString: sqlite3_errmsg(db)))")
        }

        print("Total questions deleted: \(countToDelete)")
        print("Total questions remaining: \(totalQuestions)")
        print("Total unused questions remaining: \(unusedQuestions)")
        print("Total used questions remaining: \(usedQuestions)")

        // Invoke the completion handler.
        completion?()
        print("deleteAllButLastFiveUnusedQuestions - Exited.")
    }

}
