import Foundation

enum AppLinks {
    /// Placeholder — replace with the production privacy policy URL before release.
    static let privacyPolicy = URL(string: "https://raytech.co.il/privacy/maccheck")!

    /// Placeholder support email — replace before release.
    static let supportEmail = "info@raytech.co.il"

    /// Placeholder issue reporting email — replace before release.
    static let issueEmail = "info@raytech.co.il"

    /// Placeholder Mac App Store product page — replace with the live URL before release.
    static let appStorePage = URL(string: "https://apps.apple.com/app/maccheck/id0000000000")!

    /// Opens the Mac App Store Updates page.
    static var checkForUpdatesURL: URL {
        URL(string: "macappstore://showUpdatesPage")!
    }

    /// MacCheck product page on the Raytech site.
    static let aboutMacCheck = URL(string: "https://raytech.co.il/products/maccheck")!

    /// Contact page on the MacCheck site.
    private static let contactPageURL = URL(string: "https://raytech.co.il/privacy/maccheck#contact")!

    static var contactSupportURL: URL { contactPageURL }

    static var reportIssueURL: URL { contactPageURL }

    private static var supportBody: String {
        """

        ---
        App: \(AppMetadata.appName) \(AppMetadata.version) (\(AppMetadata.buildNumber))
        """
    }

    private static func mailtoURL(to email: String, subject: String, body: String) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url ?? URL(string: "mailto:\(email)")!
    }
}
