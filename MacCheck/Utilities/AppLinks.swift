import Foundation

enum AppLinks {
    /// Placeholder — replace with the production privacy policy URL before release.
    static let privacyPolicy = URL(string: "https://raytech.app/maccheck/privacy")!

    /// Placeholder support email — replace before release.
    static let supportEmail = "support@raytech.app"

    /// Placeholder issue reporting email — replace before release.
    static let issueEmail = "support@raytech.app"

    static var contactSupportURL: URL {
        mailtoURL(
            to: supportEmail,
            subject: "MacCheck Support Request",
            body: supportBody
        )
    }

    static var reportIssueURL: URL {
        mailtoURL(
            to: issueEmail,
            subject: "MacCheck Issue Report",
            body: supportBody
        )
    }

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
