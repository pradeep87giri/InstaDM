// ContentView.swift

import SwiftUI
import WebKit

struct InstagramWebView: UIViewRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()

        // Register a channel so JavaScript can send messages to Swift
        contentController.add(context.coordinator, name: "urlChanged")

        // This JavaScript does two things:
        //
        // 1. URL watcher — intercepts SPA navigation (pushState/replaceState/popstate)
        //    and reports URL changes to Swift. Catches back-button and link taps.
        //
        // 2. Reel detector — uses a MutationObserver to watch the DOM.
        //    When a large fullscreen video appears (the reel player), it fires
        //    a signal to Swift. This catches reels that open as overlays WITHOUT
        //    changing the URL — which is why the URL watcher alone wasn't enough.

        let watcherJS = """
            (function() {

                function notifySwift(msg) {
                    if (window.webkit && window.webkit.messageHandlers.urlChanged) {
                        window.webkit.messageHandlers.urlChanged.postMessage(msg);
                    }
                }

                // --- Part 1: URL change watcher ---

                const origPush = history.pushState.bind(history);
                history.pushState = function(state, title, url) {
                    origPush(state, title, url);
                    notifySwift(window.location.href);
                };

                const origReplace = history.replaceState.bind(history);
                history.replaceState = function(state, title, url) {
                    origReplace(state, title, url);
                    notifySwift(window.location.href);
                };

                window.addEventListener('popstate', function() {
                    notifySwift(window.location.href);
                });

                window.addEventListener('hashchange', function() {
                    notifySwift(window.location.href);
                });

                // --- Part 2: Reel overlay detector ---
                // A reel player shows a fullscreen video covering most of the screen.
                // Regular DM video thumbnails are small — this distinguishes them.

                let reelCheckTimer = null;

                function checkForReelOverlay() {
                    const videos = document.querySelectorAll('video');
                    for (const video of videos) {
                        const rect = video.getBoundingClientRect();
                        const coversWidth  = rect.width  >= window.innerWidth  * 0.8;
                        const coversHeight = rect.height >= window.innerHeight * 0.5;
                        if (coversWidth && coversHeight) {
                            notifySwift('__reel_detected__');
                            return;
                        }
                    }
                }

                // Watch the DOM for new elements being added (like a reel overlay appearing)
                const domObserver = new MutationObserver(function() {
                    clearTimeout(reelCheckTimer);
                    reelCheckTimer = setTimeout(checkForReelOverlay, 250);
                });

                function startObserving() {
                    domObserver.observe(document.body, { childList: true, subtree: true });
                }

                if (document.body) {
                    startObserving();
                } else {
                    document.addEventListener('DOMContentLoaded', startObserving);
                }

            })();
        """

        contentController.addUserScript(WKUserScript(
            source: watcherJS,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))

        // Remove the grey/blue flash that appears on message rows when scrolling
        let tapHighlightCSS = """
            (function() {
                const s = document.createElement('style');
                s.textContent = '* { -webkit-tap-highlight-color: transparent !important; }';
                document.head ? document.head.appendChild(s)
                              : document.addEventListener('DOMContentLoaded', () => document.head.appendChild(s));
            })();
        """
        contentController.addUserScript(WKUserScript(
            source: tapHighlightCSS,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.decelerationRate = .normal
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        let dmURL = URL(string: "https://www.instagram.com/direct/inbox/")!
        webView.load(URLRequest(url: dmURL))

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

        // Called by JavaScript whenever the URL changes OR a reel is detected
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "urlChanged",
                  let payload = message.body as? String,
                  let webView = message.webView else { return }
            redirectIfNeeded(webView: webView, url: payload)
        }

        // Called after every full page load
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let url = webView.url?.absoluteString ?? ""
            redirectIfNeeded(webView: webView, url: url)
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            let nsError = error as NSError
            guard nsError.code != NSURLErrorCancelled else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                webView.load(URLRequest(url: URL(string: "https://www.instagram.com/direct/inbox/")!))
            }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

            guard navigationAction.targetFrame?.isMainFrame == true else {
                decisionHandler(.allow)
                return
            }

            let url = navigationAction.request.url?.absoluteString ?? ""

            let isKnownDistraction =
                url.contains("instagram.com/explore")  ||
                url.contains("instagram.com/reels")    ||
                url.contains("instagram.com/reel/")    ||
                url.contains("instagram.com/stories/") ||
                url.contains("/reel")                   ||
                (url.contains("instagram.com/p/") && !url.contains("/direct/"))

            if isKnownDistraction {
                decisionHandler(.cancel)
                DispatchQueue.main.async {
                    webView.load(URLRequest(url: URL(string: "https://www.instagram.com/direct/inbox/")!))
                }
            } else {
                decisionHandler(.allow)
            }
        }

        private func redirectIfNeeded(webView: WKWebView, url: String) {
            // If JavaScript detected a fullscreen reel overlay, redirect immediately
            if url == "__reel_detected__" {
                DispatchQueue.main.async {
                    webView.load(URLRequest(url: URL(string: "https://www.instagram.com/direct/inbox/")!))
                }
                return
            }

            let isOnDMs       = url.contains("/direct/") && !url.contains("/reel")
            let isOnLoginFlow = url.contains("/accounts/")
                             || url.contains("/challenge/")
                             || url.contains("facebook.com/login")
                             || url.contains("facebook.com/dialog")

            if !isOnDMs && !isOnLoginFlow && !url.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    webView.load(URLRequest(url: URL(string: "https://www.instagram.com/direct/inbox/")!))
                }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        InstagramWebView()
            .ignoresSafeArea(.container, edges: .bottom)
    }
}
