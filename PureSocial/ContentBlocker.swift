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

    // Forces every link/popup to navigate in the same view. Without this, links that open a new
    // tab (target="_blank") or call window.open — "Help Center", "For developers", "Log in",
    // "Continue with…" — silently do nothing in a single-view browser. Runs at document start on
    // every frame so it catches links injected later by single-page apps.
    static func navigationFixUserScript() -> WKUserScript {
        let js = """
        (function() {
            function fixAnchors(root) {
                if (!root || !root.querySelectorAll) return;
                var as = root.querySelectorAll('a[target="_blank"], a[target="_new"]');
                for (var i = 0; i < as.length; i++) { as[i].target = '_self'; }
            }
            // Route window.open through a same-frame navigation instead of a (blocked) popup.
            try {
                window.open = function(url) {
                    if (url) { try { window.location.assign(url); } catch (e) { window.location.href = url; } }
                    return window;
                };
            } catch (e) {}

            fixAnchors(document);
            new MutationObserver(function(muts) {
                for (var i = 0; i < muts.length; i++) {
                    var added = muts[i].addedNodes;
                    if (!added) continue;
                    for (var j = 0; j < added.length; j++) {
                        var n = added[j];
                        if (n.nodeType !== 1) continue;
                        if (n.tagName === 'A' && (n.target === '_blank' || n.target === '_new')) n.target = '_self';
                        fixAnchors(n);
                    }
                }
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
        case "instagram", "instagram-dm", "instagram-publish": return instagramCSS
        case "youtube":   return youtubeCSS
        case "reddit":    return redditCSS
        default:          return ""
        }
    }

    // MARK: - JS DOM hiding (second reliable layer)

    static func domHidingJS(for platformId: String) -> String {
        switch platformId {
        case "instagram", "instagram-dm", "instagram-publish": return instagramHidingJS
        default:          return "function hideContent() {}"
        }
    }

    // MARK: - Instagram

    // CSS layer: dim and disable targeted Instagram surfaces without collapsing layout.
    static let instagramCSS = """
    .ps-muted-blocked {
        display: none !important;
    }

    /* Keep the overall shell intact, just remove reels entry points. */
    a[href="/reels/"],
    a[href^="/reels"],
    [href="/reels/"] {
        display: none !important;
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

        function normalizeText(value) {
            return (value || '')
                .toLowerCase()
                .normalize('NFD')
                .replace(/[\\u0300-\\u036f]/g, '')
                .trim();
        }

        function elementHasActionLabel(el, labels) {
            if (!el) return false;

            var candidates = [
                el.textContent,
                el.getAttribute && el.getAttribute('aria-label'),
                el.getAttribute && el.getAttribute('title')
            ];

            for (var i = 0; i < candidates.length; i++) {
                var text = normalizeText(candidates[i]);
                if (!text) continue;
                for (var j = 0; j < labels.length; j++) {
                    if (text.indexOf(labels[j]) !== -1) return true;
                }
            }

            return false;
        }

        function shouldKeepArticleInteractive(article) {
            if (!article) return false;

            // Never mute nav bar, activity panels, dialogs, creation modals
            if (article.closest('[role=\"dialog\"], form, nav, [role=\"navigation\"], [role=\"tablist\"], [role=\"complementary\"], [role=\"banner\"]')) return true;
            // Never mute articles inside notification or activity containers
            if (article.closest('[aria-label*=\"otif\"], [aria-label*=\"ctivit\"], [aria-label*=\"Activity\"], [aria-label*=\"Notif\"]')) return true;

            if (article.querySelector('textarea, input:not([type=\"hidden\"]), form, [contenteditable=\"true\"], [role=\"textbox\"]')) return true;

            var publishLabels = ['publier', 'publish', 'share', 'partager', 'post', 'next', 'suivant', 'done', 'terminer'];
            var actionNodes = article.querySelectorAll('button, [role=\"button\"], a, div');
            for (var i = 0; i < actionNodes.length; i++) {
                if (elementHasActionLabel(actionNodes[i], publishLabels)) return true;
            }

            return false;
        }

        // Publications in the feed and explore grids.
        var articles = document.querySelectorAll('article');
        for (var i = 0; i < articles.length; i++) {
            if (shouldKeepArticleInteractive(articles[i])) continue;
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

    // MARK: - X / Twitter

    static let twitterCSS = """
    .ps-muted-blocked {
        opacity: 0.12 !important;
        filter: grayscale(1) saturate(0) !important;
        pointer-events: none !important;
        user-select: none !important;
    }
    .ps-muted-blocked * { pointer-events: none !important; }
    """

    static let twitterHidingJS = """
    function hideContent() {
        if (!document.body) return;

        function mute(el) {
            if (el) el.classList.add('ps-muted-blocked');
        }

        // Home / For You / Following timeline containers
        var timelineLabels = [
            '[aria-label="Home timeline"]',
            '[aria-label="Timeline: Your Home Timeline"]',
            '[aria-label*="For you"]',
            '[aria-label*="Following timeline"]'
        ];
        for (var t = 0; t < timelineLabels.length; t++) {
            var els = document.querySelectorAll(timelineLabels[t]);
            for (var i = 0; i < els.length; i++) mute(els[i]);
        }

        // Trending / What's happening
        var trending = document.querySelectorAll(
            '[aria-label*="Timeline: Trending now"], [aria-label="Who to follow"]'
        );
        for (var j = 0; j < trending.length; j++) mute(trending[j]);

        // Sidebar user suggestions (desktop) — keep DM user search intact
        var sidebar = document.querySelector('[data-testid="sidebarColumn"]');
        if (sidebar) {
            var cells = sidebar.querySelectorAll('[data-testid="UserCell"]');
            for (var k = 0; k < cells.length; k++) mute(cells[k]);
        }
    }
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
    .ps-muted-blocked {
        opacity: 0.12 !important;
        filter: grayscale(1) saturate(0) !important;
        pointer-events: none !important;
        user-select: none !important;
    }
    .ps-muted-blocked * { pointer-events: none !important; }
    """

    static let tiktokHidingJS = """
    function hideContent() {
        if (!document.body) return;

        function mute(el) {
            if (!el) return;
            el.classList.add('ps-muted-blocked');
            // Pause any autoplaying video inside
            var videos = el.querySelectorAll('video');
            for (var i = 0; i < videos.length; i++) {
                videos[i].pause();
                videos[i].autoplay = false;
            }
        }

        var feedSelectors = [
            '[data-e2e="recommend-list-item-container"]',
            '[class*="DivVideoFeed"]',
            '[class*="DivItemContainer"]',
            '[class*="VideoFeedCard"]'
        ];
        for (var s = 0; s < feedSelectors.length; s++) {
            var items = document.querySelectorAll(feedSelectors[s]);
            for (var i = 0; i < items.length; i++) mute(items[i]);
        }
    }
    """

    // MARK: - Media control (global mute / block video)

    // Returns JS that enforces the current mute/block-video settings on every media element,
    // including ones added later (MutationObserver) and ones that try to (re)start playing.
    // Safe to call repeatedly — it updates flags on an already-installed enforcer.
    static func mediaControlJS(muteSound: Bool, blockVideo: Bool) -> String {
        """
        (function() {
            window._psMuteSound = \(muteSound ? "true" : "false");
            window._psBlockVideo = \(blockVideo ? "true" : "false");

            function enforce() {
                var videos = document.querySelectorAll('video');
                for (var i = 0; i < videos.length; i++) {
                    var v = videos[i];
                    if (window._psMuteSound) { v.muted = true; v.volume = 0; }
                    if (window._psBlockVideo) {
                        try { v.pause(); } catch (e) {}
                        v.style.setProperty('display', 'none', 'important');
                    } else {
                        v.style.removeProperty('display');
                    }
                }
                var audios = document.querySelectorAll('audio');
                for (var j = 0; j < audios.length; j++) {
                    if (window._psMuteSound) { audios[j].muted = true; audios[j].volume = 0; }
                }
            }
            window._psEnforceMedia = enforce;

            if (!window._psMediaHooked) {
                window._psMediaHooked = true;
                // Re-enforce whenever media tries to start (covers autoplay & user taps).
                document.addEventListener('play', function() {
                    if (window._psMuteSound || window._psBlockVideo) enforce();
                }, true);
                document.addEventListener('volumechange', function(e) {
                    if (window._psMuteSound && e.target) { e.target.muted = true; }
                }, true);
                var target = document.documentElement || document.body;
                if (target) {
                    new MutationObserver(function() { enforce(); })
                        .observe(target, { childList: true, subtree: true });
                }
            }

            enforce();
        })();
        """
    }

    // MARK: - Helpers

    private static func escape(_ css: String) -> String {
        css
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`",  with: "\\`")
            .replacingOccurrences(of: "$",  with: "\\$")
    }
}
