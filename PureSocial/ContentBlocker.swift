import WebKit

enum ContentBlocker {

    static func userScript(for platformId: String) -> WKUserScript {
        let css = cssRules(for: platformId)
        guard !css.isEmpty else {
            return WKUserScript(source: "", injectionTime: .atDocumentStart, forMainFrameOnly: false)
        }
        let escaped = escape(css)
        let js = """
        (function() {
            function inject() {
                if (document.getElementById('ps-blocker')) return;
                var s = document.createElement('style');
                s.id = 'ps-blocker';
                s.innerHTML = `\(escaped)`;
                var t = document.head || document.documentElement;
                if (t) t.appendChild(s);
            }
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', inject);
            } else {
                inject();
            }
            // Re-apply for SPAs
            new MutationObserver(function() {
                if (!document.getElementById('ps-blocker')) inject();
            }).observe(document.documentElement, { childList: true, subtree: false });
        })();
        """
        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }

    static func reinjectJS(for platformId: String) -> String {
        let css = cssRules(for: platformId)
        guard !css.isEmpty else { return "" }
        let escaped = escape(css)
        return """
        (function() {
            var e = document.getElementById('ps-blocker');
            if (e) e.remove();
            var s = document.createElement('style');
            s.id = 'ps-blocker';
            s.innerHTML = `\(escaped)`;
            if (document.head) document.head.appendChild(s);
        })();
        """
    }

    private static func escape(_ css: String) -> String {
        css
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
    }

    static func cssRules(for platformId: String) -> String {
        switch platformId {
        case "instagram": return instagramCSS
        case "facebook":  return facebookCSS
        case "x":         return twitterCSS
        case "linkedin":  return linkedinCSS
        case "youtube":   return youtubeCSS
        case "reddit":    return redditCSS
        case "tiktok":    return tiktokCSS
        default:          return ""
        }
    }

    // MARK: - Per-Platform CSS

    // Hides: stories bar, reels tab, explore, home feed — keeps DM inbox
    static let instagramCSS = """
    [aria-label*="Stories"], [data-pagelet*="Stories"],
    ._ab8w, ._aabd, ._aabp, ._aabr { display: none !important; }
    [aria-label*="Reels"], [href*="/reels/"],
    a[href="/reels/"], svg[aria-label*="Reels"] { display: none !important; }
    [aria-label*="Explore"], [href*="/explore/"] { display: none !important; }
    [aria-label*="Suggested posts"] { display: none !important; }
    main article { display: none !important; }
    """

    // Hides: news feed, stories, reels, watch, marketplace, gaming — keeps messages
    static let facebookCSS = """
    [data-pagelet*="Stories"], [data-pagelet*="Reels"],
    [role="feed"], [data-pagelet*="FeedUnit"] { display: none !important; }
    [aria-label*="Watch"], [href*="/watch"] { display: none !important; }
    [aria-label*="Marketplace"], [href*="/marketplace"] { display: none !important; }
    [aria-label*="Gaming"], [href*="/gaming"] { display: none !important; }
    [aria-label*="Videos"], [href*="/video/"] { display: none !important; }
    """

    // Hides: home timeline, trending sidebar, who-to-follow — keeps DMs
    static let twitterCSS = """
    [data-testid="primaryColumn"] [data-testid="tweet"] { display: none !important; }
    [aria-label*="Timeline: Trending now"] { display: none !important; }
    [data-testid="sidebarColumn"] { display: none !important; }
    [data-testid="UserCell"] { display: none !important; }
    [aria-label="Who to follow"] { display: none !important; }
    """

    // Hides: home feed, discovery, news sidebar — keeps messaging
    static let linkedinCSS = """
    .feed-container-theme,
    .scaffold-finite-scroll__content,
    [data-finite-scroll-hotkey-context="FEED"] { display: none !important; }
    .discovery-templates-vertical-list { display: none !important; }
    .news-module, .trending-topics { display: none !important; }
    .feed-identity-module { display: none !important; }
    """

    // Hides: home grid, shorts shelf, watch-next recommendations
    static let youtubeCSS = """
    ytd-browse[page-subtype="home"] ytd-rich-grid-renderer { display: none !important; }
    ytd-rich-shelf-renderer[is-shorts],
    ytd-reel-shelf-renderer, ytd-shorts { display: none !important; }
    ytd-watch-next-secondary-results-renderer { display: none !important; }
    .ytp-endscreen-content { display: none !important; }
    a[href^="/shorts/"] { display: none !important; }
    """

    // Hides: post listings, ads
    static let redditCSS = """
    .ListingLayout-outerContainer > div:nth-child(2) .Post { display: none !important; }
    [data-testid="posts-list"] > * { display: none !important; }
    .promotedlink { display: none !important; }
    """

    // Hides: for-you feed, explore
    static let tiktokCSS = """
    [data-e2e="recommend-list-item-container"] { display: none !important; }
    [class*="DivVideoFeed"] { display: none !important; }
    [class*="DivItemContainer"] { display: none !important; }
    """
}
