import Foundation

enum LMAppRoute: Hashable {
    case onboarding
    case main
    case digestPost(title: String, url: URL)
}
