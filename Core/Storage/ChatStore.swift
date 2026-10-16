import Foundation
import Combine

@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var stories: [ChatStory] = []

    private let fileName = "chatcraft_stories.json"

    init() {
        load()
    }

    var storageURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }

    func load() {
        do {
            let url = storageURL
            guard FileManager.default.fileExists(atPath: url.path) else {
                stories = []
                return
            }
            let data = try Data(contentsOf: url)
            stories = normalizeLegacyThemeIDs(
                in: removeLegacySampleStories(from: try JSONDecoder.dateDecoder.decode([ChatStory].self, from: data))
            )
            save()
        } catch {
            stories = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder.prettyDateEncoder.encode(stories)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            print("ChatStore save failed: \(error.localizedDescription)")
        }
    }

    func addStory(_ story: ChatStory) {
        var next = story
        next.updatedAt = Date()
        AppAnalytics.shared.track(.storyCreate, ["theme_id": next.themeID, "format": next.format.rawValue, "character_count": next.characters.count])
        stories.insert(next, at: 0)
        save()
    }

    func updateStory(_ story: ChatStory) {
        guard let index = stories.firstIndex(where: { $0.id == story.id }) else { return }
        var next = story
        next.updatedAt = Date()
        stories[index] = next
        stories.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func deleteStory(_ story: ChatStory) {
        AppAnalytics.shared.track(.storyDelete, ["message_count": story.messages.count])
        stories.removeAll { $0.id == story.id }
        save()
    }

    func duplicateStory(_ story: ChatStory) {
        AppAnalytics.shared.track(.storyDuplicate, ["theme_id": story.themeID])
        var clone = story
        clone.id = UUID()
        clone.title = "\(story.title) Copy"
        clone.createdAt = Date()
        clone.updatedAt = Date()
        stories.insert(clone, at: 0)
        save()
    }

    func story(with id: UUID) -> ChatStory? {
        stories.first { $0.id == id }
    }

    private func removeLegacySampleStories(from loadedStories: [ChatStory]) -> [ChatStory] {
        loadedStories.filter { !isLegacySampleStory($0) }
    }

    private func normalizeLegacyThemeIDs(in loadedStories: [ChatStory]) -> [ChatStory] {
        loadedStories.map { story in
            var next = story
            next.themeID = ChatTheme.normalizedID(for: story.themeID)
            return next
        }
    }

    private func isLegacySampleStory(_ story: ChatStory) -> Bool {
        let messageTexts = Set(story.messages.map { $0.text })

        if story.title == "Midnight Plot Twist",
           story.themeID == "blue-bubble",
           messageTexts.isSuperset(of: Set([
               "Today",
               "You will not believe what just happened.",
               "That sounds like the start of a very suspicious story.",
               "typing...",
               "The locked room had a second key.",
               "😳"
           ])) {
            return true
        }

        if story.title == "Launch Day Drama",
           story.themeID == "green-bubble",
           messageTexts.isSuperset(of: Set([
               "The trailer is live.",
               "Refresh count?",
               "Moving way too fast.",
               "🔥"
           ])) {
            return true
        }

        return false
    }
}

extension JSONEncoder {
    static var prettyDateEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var dateDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
