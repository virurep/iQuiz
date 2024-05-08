import SwiftUI

struct QuizTopic: Identifiable, Codable {
    let id = UUID()
    let title: String
    let desc: String
    let questions: [Question]
}

struct ContentView: View {
    @State private var showingPopover = false
    @State private var newURL = "https://tednewardsandbox.site44.com/questions.json" // Default URL
    @State private var quizTopics: [QuizTopic] = []
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List(quizTopics) { topic in
                NavigationLink(destination: QuestionListView(topic: topic)) {
                    QuizTopicRow(topic: topic)
                }
            }
            .navigationBarTitle("iQuiz")
            .navigationBarItems(trailing:
                Button(action: {
                    showingPopover = true
                }) {
                    Text("Settings")
                }
                .popover(isPresented: $showingPopover, arrowEdge: .trailing) {
                    VStack {
                        Text("Delete the current URL and enter a new data source here!")
                        TextField("Enter URL", text: $newURL)
                            .padding()
                        Button("Check Now") {
                            getData(from: newURL)
                            showingPopover = false // Dismiss the popover after checking the new URL
                        }
                        .padding()
                    }
                }
            )
            .onAppear {
                getData(from: newURL) // Load data from the default URL on app launch
            }
            .alert(isPresented: Binding<Bool>(
                get: { alertMessage != "" },
                set: { _,_  in })) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func getData(from url: String) {
        guard let url = URL(string: url) else {
            alertMessage = "Invalid URL"
            return
        }
        
        if !Reachability.isConnectedToNetwork() {
            alertMessage = "Network is not available"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let quizData = try decoder.decode([QuizTopic].self, from: data)
                    DispatchQueue.main.async {
                        self.quizTopics = quizData
                        UserDefaults.standard.set(url.absoluteString, forKey: "quizDataURL") // Store the new URL in UserDefaults
                    }
                } catch {
                    alertMessage = "Error decoding JSON: \(error.localizedDescription)"
                }
            } else if let error = error {
                alertMessage = "Error fetching data: \(error.localizedDescription)"
            }
        }.resume()
    }
}


    
struct QuizTopicRow: View {
    let topic: QuizTopic
    
    var body: some View {
        HStack {
            Image(systemName: "questionmark.circle")
                .resizable()
                .frame(width: 30, height: 30)
            VStack(alignment: .leading) {
                Text(topic.title)
                    .font(.headline)
                Text(topic.desc)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Question: Codable {
    let text: String
    let answer: String
    let answers: [String]
}

struct QuestionListView: View {
    let topic: QuizTopic
    @State private var currentQuestionIndex = 0
    @State private var userAnswers: [String?] = []
    @State private var isAnswerViewPresented = false
    @State private var userScore = 0 // Add user score property
    
    var totalQuestions: Int {
        topic.questions.count
    }
    
    var currentQuestion: Question {
        topic.questions[currentQuestionIndex]
    }
    
    var body: some View {
        VStack {
            if currentQuestionIndex < topic.questions.count {
                if isAnswerViewPresented {
                    AnswerView(question: currentQuestion, correctAnswer: currentQuestion.answers[Int(currentQuestion.answer)! - 1], userAnswer: userAnswers[currentQuestionIndex], dismissAction: {
                        isAnswerViewPresented = false
                        currentQuestionIndex += 1
                    })
                } else {
                    QuestionView(question: currentQuestion, didSelectAnswerIndex: { answerIndex in
                        let userAnswer = currentQuestion.answers[answerIndex]
                        userAnswers.append(userAnswer)
                        if userAnswer == currentQuestion.answers[Int(currentQuestion.answer)! - 1] {
                            userScore += 1
                        }
                        isAnswerViewPresented = true
                    })
                }
            } else {
                FinishedView(score: userScore, totalQuestions: totalQuestions)
            }
        }
    }
}


struct QuestionView: View {
    let question: Question
    let didSelectAnswerIndex: (Int) -> Void
    @State private var selectedAnswerIndex: Int?
    
    var body: some View {
        VStack {
            Text(question.text)
                .font(.title)
                .padding()
            
            ForEach(question.answers.indices, id: \.self) { index in
                Button(action: {
                    selectedAnswerIndex = index
                    didSelectAnswerIndex(index)
                }) {
                    HStack {
                        Image(systemName: selectedAnswerIndex == index ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedAnswerIndex == index ? .green : .gray)
                        Text(question.answers[index])
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
    }
}

struct AnswerView: View {
    let question: Question
    let correctAnswer: String
    let userAnswer: String?
    let dismissAction: () -> Void
    
    var isAnswerCorrect: Bool {
        userAnswer == correctAnswer
    }
    
    var body: some View {
        VStack {
            
            Text(question.text)
                .padding()
                .font(.title)
            Text("Correct Answer: \(correctAnswer)")
                .padding()
                .foregroundColor(isAnswerCorrect ? .green : .red)
                .font(.title)
            Text(isAnswerCorrect ? "+1" : " ")
                .foregroundColor(.green)
            Button("Next") {
                dismissAction()
            }
            .padding()
        }
    }
}

struct Reachability {
    static func isConnectedToNetwork() -> Bool {
        return true
    }
}


struct FinishedView: View {
    let score: Int
    let totalQuestions: Int
    
    var scoreText: String {
        let percentage = Double(score) / Double(totalQuestions)
        switch percentage {
        case 1.0:
            return "Perfect!"
        case 0.9..<1.0:
            return "Almost perfect!"
        case 0.7..<0.9:
            return "Great job!"
        case 0.5..<0.7:
            return "Not bad!"
        default:
            return "Keep practicing!"
        }
    }
    
    var body: some View {
        VStack {
            Text(scoreText)
                .font(.title)
                .padding()
            Text("Your Score: \(score) of \(totalQuestions) correct")
                .font(.headline)
                .padding()
        }
    }
}

