import SwiftUI

struct SocialPlatform: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let startURL: String
    var isEnabled: Bool

    static let defaults: [SocialPlatform] = [
        SocialPlatform(id: "whatsapp",   name: "WhatsApp",    startURL: "https://web.whatsapp.com",                   isEnabled: true),
        SocialPlatform(id: "instagram",         name: "Instagram",    startURL: "https://www.instagram.com/direct/inbox/",   isEnabled: true),
        SocialPlatform(id: "instagram-dm",      name: "IG Messages",  startURL: "https://www.instagram.com/direct/inbox/",   isEnabled: false),
        SocialPlatform(id: "instagram-publish", name: "IG Publish",   startURL: "https://www.instagram.com/",                isEnabled: false),
        SocialPlatform(id: "messenger",         name: "Messenger",    startURL: "https://www.messenger.com",                 isEnabled: false),
        SocialPlatform(id: "gmail",      name: "Gmail",       startURL: "https://mail.google.com/mail/u/0/#inbox",    isEnabled: true),
        SocialPlatform(id: "x",          name: "X / Twitter", startURL: "https://x.com/messages",                    isEnabled: true),
        SocialPlatform(id: "linkedin",   name: "LinkedIn",    startURL: "https://www.linkedin.com/messaging/",        isEnabled: true),
        SocialPlatform(id: "telegram",   name: "Telegram",    startURL: "https://web.telegram.org/k/",                isEnabled: true),
        SocialPlatform(id: "reddit",     name: "Reddit",      startURL: "https://www.reddit.com/message/inbox/",      isEnabled: false),
        SocialPlatform(id: "snapchat",   name: "Snapchat",    startURL: "https://web.snapchat.com",                   isEnabled: false),
        SocialPlatform(id: "youtube",    name: "YouTube",     startURL: "https://www.youtube.com/feed/subscriptions", isEnabled: false),
        SocialPlatform(id: "tiktok",     name: "TikTok",      startURL: "https://www.tiktok.com/messages",            isEnabled: false),
    ]

    var shortLabel: String {
        switch id {
        case "whatsapp":   return "WA"
        case "instagram":         return "IG"
        case "instagram-dm":      return "DM"
        case "instagram-publish": return "POST"
        case "messenger":         return "MS"
        case "gmail":      return "GM"
        case "x":          return "X"
        case "linkedin":   return "LI"
        case "telegram":   return "TG"
        case "reddit":     return "RE"
        case "snapchat":   return "SC"
        case "youtube":    return "YT"
        case "tiktok":     return "TT"
        default:          return String(name.prefix(3)).uppercased()
        }
    }

    var tabLabel: String {
        switch id {
        case "whatsapp":   return "CHAT"
        case "instagram":         return "PHOTOS"
        case "instagram-dm":      return "DMs"
        case "instagram-publish": return "PUBLISH"
        case "messenger":         return "DMs"
        case "gmail":      return "MAIL"
        case "x":          return "POSTS"
        case "linkedin":   return "NETWORK"
        case "telegram":   return "CHAT"
        case "reddit":     return "INBOX"
        case "snapchat":   return "SNAPS"
        case "youtube":    return "SUBS"
        case "tiktok":     return "TT"
        default:          return String(name.prefix(6)).uppercased()
        }
    }

    var systemIconName: String {
        switch id {
        case "whatsapp":   return "phone.bubble.left.fill"
        case "instagram":         return "camera.fill"
        case "instagram-dm":      return "message.fill"
        case "instagram-publish": return "plus.square.fill"
        case "messenger":         return "bubble.left.and.bubble.right.fill"
        case "gmail":      return "envelope.fill"
        case "x":          return "bird.fill"
        case "linkedin":   return "briefcase.fill"
        case "telegram":   return "paperplane.fill"
        case "reddit":     return "text.bubble.fill"
        case "snapchat":   return "bolt.fill"
        case "youtube":    return "play.rectangle.fill"
        case "tiktok":     return "music.note"
        default:          return "globe"
        }
    }

    // URL to open the post-creation flow for platforms that support it
    var composeURL: String? {
        switch id {
        case "instagram": return "https://www.instagram.com/"
        case "x":         return "https://x.com/compose/tweet"
        case "linkedin":  return "https://www.linkedin.com/feed/"
        case "reddit":    return "https://www.reddit.com/submit"
        default:          return nil
        }
    }

    // True for platforms whose own auth flows go through accounts.google.com (Gmail, YouTube).
    var ownsGoogleAuth: Bool {
        id == "gmail" || id == "youtube"
    }

    // Per-platform user agent override. nil = use the global mobile Safari UA.
    // Messenger needs a desktop UA so messenger.com serves its full web interface
    // instead of the stripped mobile shell.
    var customUserAgent: String? {
        switch id {
        case "messenger":
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        default:
            return nil
        }
    }

    var accentColor: Color {
        switch id {
        case "whatsapp":   return Color(red: 0.07, green: 0.74, blue: 0.42)
        case "instagram":         return Color(red: 0.83, green: 0.19, blue: 0.52)
        case "instagram-dm":      return Color(red: 0.83, green: 0.19, blue: 0.52)
        case "instagram-publish": return Color(red: 0.83, green: 0.19, blue: 0.52)
        case "messenger":  return Color(red: 0.00, green: 0.53, blue: 1.00)
        case "gmail":      return Color(red: 0.92, green: 0.26, blue: 0.21)
        case "x":          return Color(red: 0.10, green: 0.10, blue: 0.10)
        case "linkedin":   return Color(red: 0.00, green: 0.47, blue: 0.71)
        case "telegram":   return Color(red: 0.18, green: 0.61, blue: 0.87)
        case "reddit":     return Color(red: 1.00, green: 0.27, blue: 0.00)
        case "snapchat":   return Color(red: 1.00, green: 0.80, blue: 0.00)
        case "youtube":    return Color(red: 1.00, green: 0.00, blue: 0.00)
        case "tiktok":     return Color(red: 0.00, green: 0.89, blue: 0.80)
        default:          return .blue
        }
    }
}
