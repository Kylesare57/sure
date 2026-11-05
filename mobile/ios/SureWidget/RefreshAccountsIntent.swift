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

    /// Empty (the default) shows every account. When accounts are picked, only
    /// those are shown, in the order they were picked.
    @Parameter(title: "Accounts", description: "Pick the accounts to show. Leave empty to show all of them.")
    var accounts: [WidgetAccountEntity]?

    @Parameter(title: "Show liabilities", description: "Only used when no accounts are picked.", default: true)
    var showLiabilities: Bool

    @Parameter(title: "Show net worth", default: true)
    var showNetWorth: Bool
}

/// An account as it appears in the "Accounts" picker under "Edit Widget".
struct WidgetAccountEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Account"
    static let defaultQuery = WidgetAccountQuery()

    let id: String
    let name: String
    let detail: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(detail)")
    }

    init(id: String, name: String, detail: String) {
        self.id = id
        self.name = name
        self.detail = detail
    }

    /// The subtitle tells apart accounts with the same name (e.g. two "Savings").
    init(_ account: SureWidgetAccount) {
        let kind = account.isLiability ? "Liability" : (account.accountType.map(Self.prettyType) ?? "")
        let parts = [account.institutionName ?? "", kind, account.balance]
        self.init(id: account.id, name: account.name, detail: parts.filter { !$0.isEmpty }.joined(separator: " · "))
    }

    private static func prettyType(_ raw: String) -> String {
        switch raw.lowercased() {
        case "depository": return "Cash"
        case "creditcard", "credit_card": return "Credit card"
        case "otherasset", "other_asset": return "Other asset"
        case "otherliability", "other_liability": return "Other liability"
        default: return raw.prefix(1).uppercased() + raw.dropFirst()
        }
    }
}

/// Offers the accounts from the last snapshot the widget or the app saved, so
/// the picker works offline and never needs the API key.
struct WidgetAccountQuery: EntityQuery {
    func entities(for identifiers: [WidgetAccountEntity.ID]) async throws -> [WidgetAccountEntity] {
        let known = Self.all()
        return identifiers.map { id in
            // An account that's gone from Sure stays selectable so the setting isn't silently lost.
            known.first { $0.id == id } ?? WidgetAccountEntity(id: id, name: "Account no longer in Sure", detail: "")
        }
    }

    func suggestedEntities() async throws -> [WidgetAccountEntity] {
        Self.all()
    }

    private static func all() -> [WidgetAccountEntity] {
        let accounts = SureWidgetStore.loadSnapshot()?.accounts ?? []
        // Assets first, then liabilities, each alphabetical, so similar accounts sit together.
        return accounts
            .sorted { a, b in
                if a.isLiability != b.isLiability { return !a.isLiability }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            .map { WidgetAccountEntity($0) }
    }
}
