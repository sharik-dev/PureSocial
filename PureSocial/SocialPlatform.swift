import SwiftUI

struct SocialPlatform: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let startURL: String
    var isEnabled: Bool

    static let defaults: [SocialPlatform] = [
        SocialPlatform(id: "whatsapp",  name: "WhatsApp",    startURL: "https://web.whatsapp.com",                   isEnabled: true),
        SocialPlatform(id: "messenger", name: "Messenger",   startURL: "https://www.messenger.com",                  isEnabled: true),
        SocialPlatform(id: "instagram", name: "Instagram",   startURL: "https://www.instagram.com/direct/inbox/",    isEnabled: true),
        SocialPlatform(id: "facebook",  name: "Facebook",    startURL: "https://www.facebook.com/messages/",         isEnabled: true),
        SocialPlatform(id: "x",         name: "X / Twitter", startURL: "https://x.com/messages",                    isEnabled: true),
        SocialPlatform(id: "linkedin",  name: "LinkedIn",    startURL: "https://www.linkedin.com/messaging/",        isEnabled: true),
        SocialPlatform(id: "telegram",  name: "Telegram",    startURL: "https://web.telegram.org/k/",                isEnabled: true),
        SocialPlatform(id: "reddit",    name: "Reddit",      startURL: "https://www.reddit.com/message/inbox/",      isEnabled: false),
        SocialPlatform(id: "snapchat",  name: "Snapchat",    startURL: "https://web.snapchat.com",                   isEnabled: false),
        SocialPlatform(id: "youtube",   name: "YouTube",     startURL: "https://www.youtube.com/feed/subscriptions", isEnabled: false),
        SocialPlatform(id: "tiktok",    name: "TikTok",      startURL: "https://www.tiktok.com/messages",            isEnabled: false),
    ]

    var systemIconName: String {
        switch id {
        case "whatsapp":  return "phone.bubble.left.fill"
        case "messenger": return "message.fill"
        case "instagram": return "camera.fill"
        case "facebook":  return "person.2.fill"
        case "x":         return "bird.fill"
        case "linkedin":  return "briefcase.fill"
        case "telegram":  return "paperplane.fill"
        case "reddit":    return "text.bubble.fill"
        case "snapchat":  return "bolt.fill"
        case "youtube":   return "play.rectangle.fill"
        case "tiktok":    return "music.note"
        default:          return "globe"
        }
    }

    var accentColor: Color {
        switch id {
        case "whatsapp":  return Color(red: 0.07, green: 0.74, blue: 0.42)
        case "messenger": return Color(red: 0.00, green: 0.56, blue: 1.00)
        case "instagram": return Color(red: 0.83, green: 0.19, blue: 0.52)
        case "facebook":  return Color(red: 0.23, green: 0.35, blue: 0.60)
        case "x":         return Color(red: 0.10, green: 0.10, blue: 0.10)
        case "linkedin":  return Color(red: 0.00, green: 0.47, blue: 0.71)
        case "telegram":  return Color(red: 0.18, green: 0.61, blue: 0.87)
        case "reddit":    return Color(red: 1.00, green: 0.27, blue: 0.00)
        case "snapchat":  return Color(red: 1.00, green: 0.80, blue: 0.00)
        case "youtube":   return Color(red: 1.00, green: 0.00, blue: 0.00)
        case "tiktok":    return Color(red: 0.00, green: 0.89, blue: 0.80)
        default:          return .blue
        }
    }
}
