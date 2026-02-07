import Foundation

struct DailyPrompt {
    let question: String
    let explanation: String
}

enum DailyPrompts {
    static let prompts: [DailyPrompt] = [
        DailyPrompt(
            question: "What's one thing you're grateful for today?",
            explanation: "Gratitude helps shift focus to the positive aspects of life."
        ),
        DailyPrompt(
            question: "What challenge are you currently facing?",
            explanation: "Naming our challenges is the first step to overcoming them."
        ),
        DailyPrompt(
            question: "What's something you learned recently?",
            explanation: "Reflection on learning reinforces growth and curiosity."
        ),
        DailyPrompt(
            question: "Who made a positive impact on your day?",
            explanation: "Recognizing others strengthens our connections."
        ),
        DailyPrompt(
            question: "What's one small win you had today?",
            explanation: "Celebrating small victories builds momentum for bigger goals."
        ),
        DailyPrompt(
            question: "What would make tomorrow great?",
            explanation: "Setting intentions helps us create the day we want."
        ),
        DailyPrompt(
            question: "What's something you're looking forward to?",
            explanation: "Anticipation of positive events boosts our mood."
        ),
        DailyPrompt(
            question: "How did you take care of yourself today?",
            explanation: "Self-care awareness helps us prioritize our wellbeing."
        ),
        DailyPrompt(
            question: "What's a conversation you've been meaning to have?",
            explanation: "Important conversations often get delayed but rarely regretted."
        ),
        DailyPrompt(
            question: "What would you tell your younger self?",
            explanation: "Wisdom comes from reflecting on our journey."
        )
    ]

    static var todaysPrompt: DailyPrompt {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % prompts.count
        return prompts[index]
    }

    static var todaysPrompts: [DailyPrompt] {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let startIndex = (dayOfYear - 1) % prompts.count

        var result: [DailyPrompt] = []
        for i in 0..<5 {
            let index = (startIndex + i) % prompts.count
            result.append(prompts[index])
        }
        return result
    }
}
