import WebKit

enum ContentBlocker {

    // MARK: - Main entry point

    static func userScript(for platformId: String) -> WKUserScript {
        let css     = cssRules(for: platformId)
        let extraJS = domHidingJS(for: platformId)
        let escapedCSS = escape(css)

        let js = """
        (function() {

            // ── 1. CSS injection ──────────────────────────────────────
            function injectCSS() {
                if (document.getElementById('ps-blocker')) return;
                var s = document.createElement('style');
                s.id = 'ps-blocker';
                s.innerHTML = `\(escapedCSS)`;
                var t = document.head || document.documentElement;
                if (t) t.appendChild(s);
            }

            // ── 2. Platform-specific DOM hiding ───────────────────────
            \(extraJS)

            // Expose globally so reinjectJS (called from Swift didFinish) can re-run it
            window._psHide = hideContent;

            // ── 3. Run both on every relevant DOM change ──────────────
            function runAll() { injectCSS(); hideContent(); }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', runAll);
            } else {
                runAll();
            }

            // Debounced MutationObserver — catches SPA navigation & lazy content
            var _t;
            new MutationObserver(function() {
                if (!document.getElementById('ps-blocker')) injectCSS();
                clearTimeout(_t);
                _t = setTimeout(hideContent, 80);
            }).observe(document.documentElement, { childList: true, subtree: true });

        })();
        """
        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }

    // Called again on every didFinish navigation (belt-and-suspenders)
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
            if (typeof window._psHide === 'function') window._psHide();
        })();
        """
    }

    // MARK: - CSS rules (first fast layer)

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

    // MARK: - JS DOM hiding (second reliable layer)

    static func domHidingJS(for platformId: String) -> String {
        switch platformId {
        case "instagram": return instagramHidingJS
        default:          return "function hideContent() {}"
        }
    }

    // MARK: - Instagram

    // CSS layer: dim and disable targeted Instagram surfaces without collapsing layout.
    static let instagramCSS = """
    .ps-muted-blocked {
        opacity: 0.12 !important;
        filter: grayscale(1) saturate(0) !important;
        pointer-events: none !important;
        user-select: none !important;
    }

    .ps-muted-blocked * {
        pointer-events: none !important;
    }

    /* Keep the overall shell intact, just disable reels entry points. */
    a[href="/reels/"],
    a[href^="/reels"],
    [href="/reels/"] {
        opacity: 0.12 !important;
        filter: grayscale(1) saturate(0) !important;
        pointer-events: none !important;
    }

    /* Story viewer should not be usable if it opens. */
    [role="dialog"]:has([aria-label*="tory" i]) {
        opacity: 0.12 !important;
        filter: grayscale(1) saturate(0) !important;
        pointer-events: none !important;
    }
    """

    // JS layer: tags stories, reels and publications without removing their containers.
    static let instagramHidingJS = """
    function hideContent() {
        if (!document.body) return;

        function mute(el) {
            if (!el) return;
            el.classList.add('ps-muted-blocked');
        }

        function closestMatching(start, predicate, maxDepth) {
            var el = start;
            for (var i = 0; i < maxDepth; i++) {
                if (!el || el === document.body) break;
                if (predicate(el)) return el;
                el = el.parentElement;
            }
            return null;
        }

        // Publications in the feed and explore grids.
        var articles = document.querySelectorAll('article');
        for (var i = 0; i < articles.length; i++) {
            mute(articles[i]);
        }

        // Reels links/buttons that may appear in nav or inline modules.
        var reelTargets = document.querySelectorAll('a[href=\"/reels/\"], a[href^=\"/reels\"], [aria-label*=\"Reels\"]');
        for (var j = 0; j < reelTargets.length; j++) {
            mute(closestMatching(reelTargets[j], function(el) {
                return el.tagName === 'A' || el.getAttribute('role') === 'button' || el.children.length > 0;
            }, 5) || reelTargets[j]);
        }

        function containsStoryCreationLabel(el) {
            if (!el) return false;
            var text = (el.textContent || '').trim();
            return text.indexOf('Your story') !== -1 || text.indexOf('Add to story') !== -1;
        }

        // Stories row: keep the creation tile active, mute the rest.
        var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null, false);
        var node;
        while ((node = walker.nextNode())) {
            var text = node.textContent.trim();
            if (text !== 'Your story' && text !== 'Story' && text !== 'Stories') continue;

            var storyContainer = closestMatching(node.parentElement, function(el) {
                if (el.matches && (el.matches('[aria-label=\"Stories\"]') || el.matches('[aria-label*=\"stories\" i]'))) {
                    return true;
                }
                var style = window.getComputedStyle(el);
                return (style.overflowX === 'scroll' || style.overflowX === 'auto') && el.querySelectorAll('canvas, img').length >= 3;
            }, 10);

            if (storyContainer) {
                var keptCreationTile = false;
                for (var k = 0; k < storyContainer.children.length; k++) {
                    var child = storyContainer.children[k];
                    if (containsStoryCreationLabel(child)) {
                        keptCreationTile = true;
                        continue;
                    }
                    mute(child);
                }

                if (!keptCreationTile) {
                    mute(storyContainer);
                }
            }
        }
    }
    """

    // MARK: - Facebook

    static let facebookCSS = """
    [data-pagelet*="Stories"], [data-pagelet*="Reels"],
    [role="feed"], [data-pagelet*="FeedUnit"] { display: none !important; }
    [aria-label*="Watch"], [href*="/watch"] { display: none !important; }
    [aria-label*="Marketplace"], [href*="/marketplace"] { display: none !important; }
    [aria-label*="Gaming"], [href*="/gaming"] { display: none !important; }
    [aria-label*="Videos"], [href*="/video/"] { display: none !important; }
    """

    // MARK: - X / Twitter

    static let twitterCSS = """
    [data-testid="primaryColumn"] [data-testid="tweet"] { display: none !important; }
    [aria-label*="Timeline: Trending now"] { display: none !important; }
    [data-testid="sidebarColumn"] { display: none !important; }
    [data-testid="UserCell"] { display: none !important; }
    [aria-label="Who to follow"] { display: none !important; }
    """

    // MARK: - LinkedIn

    static let linkedinCSS = """
    .feed-container-theme,
    .scaffold-finite-scroll__content,
    [data-finite-scroll-hotkey-context="FEED"] { display: none !important; }
    .discovery-templates-vertical-list { display: none !important; }
    .news-module, .trending-topics { display: none !important; }
    .feed-identity-module { display: none !important; }
    """

    // MARK: - YouTube

    static let youtubeCSS = """
    ytd-browse[page-subtype="home"] ytd-rich-grid-renderer { display: none !important; }
    ytd-rich-shelf-renderer[is-shorts],
    ytd-reel-shelf-renderer, ytd-shorts { display: none !important; }
    ytd-watch-next-secondary-results-renderer { display: none !important; }
    .ytp-endscreen-content { display: none !important; }
    a[href^="/shorts/"] { display: none !important; }
    """

    // MARK: - Reddit

    static let redditCSS = """
    .ListingLayout-outerContainer > div:nth-child(2) .Post { display: none !important; }
    [data-testid="posts-list"] > * { display: none !important; }
    .promotedlink { display: none !important; }
    """

    // MARK: - TikTok

    static let tiktokCSS = """
    [data-e2e="recommend-list-item-container"] { display: none !important; }
    [class*="DivVideoFeed"] { display: none !important; }
    [class*="DivItemContainer"] { display: none !important; }
    """

    // MARK: - Helpers

    private static func escape(_ css: String) -> String {
        css
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`",  with: "\\`")
            .replacingOccurrences(of: "$",  with: "\\$")
    }
}
