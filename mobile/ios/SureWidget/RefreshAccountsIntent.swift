import AppIntents
import WidgetKit

/// Runs when the refresh button on the widget is tapped. It fetches fresh
/// balances in the background (without opening the app); WidgetKit then
/// reloads the widget, which picks up the snapshot this saved.
struct RefreshAccountsIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh Sure balances"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        _ = await SureWidgetAPI.refreshSnapshot()
        return .result()
    }
}

/// Widget settings shown under "Edit Widget".
struct AccountsWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Account Balances"
    static let description = IntentDescription("Shows your Sure account balances.")

    @Parameter(title: "Checking", default: true)
    var showChecking: Bool

    @Parameter(title: "Savings", description: "Savings accounts, including ones set aside for bills or goals.", default: true)
    var showSavings: Bool

    @Parameter(title: "Investments & other assets", default: true)
    var showOtherAssets: Bool

    @Parameter(title: "Credit cards & loans", default: true)
    var showLiabilities: Bool

    @Parameter(title: "Show net worth", default: true)
    var showNetWorth: Bool
}
