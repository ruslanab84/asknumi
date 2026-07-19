//
//  L10n.swift
//  Ask Numi
//
//  The single access point for all localized strings.
//  Only this file may call into LocalizationManager.
//

import Foundation

enum L10n {

    // MARK: - Tab Bar

    enum Tab {
        static var home: String       { l("tab.home") }
        static var operations: String { l("tab.operations") }
        static var assistant: String  { l("tab.assistant") }
        static var plan: String       { l("tab.plan") }
    }

    // MARK: - Common

    enum Common {
        static var cancel: String  { l("common.button.cancel") }
        static var save: String    { l("common.button.save") }
        static var saving: String  { l("common.button.saving") }
        static var retry: String   { l("common.button.retry") }
        static var back: String    { l("common.accessibility.back") }
        static var income: String  { l("common.kind.income") }
        static var expense: String { l("common.kind.expense") }
    }

    // MARK: - Dashboard

    enum Dashboard {
        static var title: String            { l("dashboard.header.title") }
        static var settingsLabel: String    { l("dashboard.header.accessibility.settings") }
        static func greeting(_ name: String) -> String {
            String(format: l("dashboard.greeting"), name)
        }
        static var totalBalance: String     { l("dashboard.balance_card.label.total_balance") }
        static var hideBalance: String      { l("dashboard.balance_card.accessibility.hide") }
        static var showBalance: String      { l("dashboard.balance_card.accessibility.show") }
        static var thisMonth: String        { l("dashboard.label.this_month") }
        static var spendingOverview: String { l("dashboard.spending.title") }
        static var spendingEmpty: String    { l("dashboard.spending.empty") }
        static var dailyTipTitle: String    { l("dashboard.daily_tip.title") }
        static var dailyTips: [String] {
            (1...31).map { l("dashboard.daily_tip.\($0)") }
        }
        static func budgetTitle(_ month: String) -> String {
            String(format: l("dashboard.budget_card.title"), month)
        }
        static var spent: String            { l("dashboard.budget_card.label.spent") }
        static var budgetPlan: String       { l("dashboard.budget_card.label.plan") }
        static func budgetRemaining(_ amount: String) -> String {
            String(format: l("dashboard.budget_card.label.remaining"), amount)
        }
        static func budgetPerDay(_ amount: String) -> String {
            String(format: l("dashboard.budget_card.label.per_day"), amount)
        }
        static func budgetOverBy(_ amount: String) -> String {
            String(format: l("dashboard.budget_card.label.over_by"), amount)
        }
        static var budgetEmptyTitle: String { l("dashboard.budget_card.empty.title") }
        static var budgetEmptyMessage: String { l("dashboard.budget_card.empty.message") }
        static var budgetSetup: String { l("dashboard.budget_card.cta.setup") }
        static var insightTitle: String     { l("dashboard.insight_card.title") }
        static var insightShowDetails: String { l("dashboard.insight_card.cta.show_details") }
        static func insightTopCategory(_ category: String, _ amount: String, _ currency: String) -> String {
            String(format: l("dashboard.insight_card.top_category"), category, amount, currency)
        }
        static func insightRecordedIncome(_ amount: String, _ currency: String) -> String {
            String(format: l("dashboard.insight_card.recorded_income"), amount, currency)
        }
        static var insightEmpty: String { l("dashboard.insight_card.empty") }
        static var attentionTitle: String { l("dashboard.attention.title") }
        static var financialTwinTitle: String { l("dashboard.financial_twin.title") }
        static var financialTwinEmpty: String { l("dashboard.financial_twin.empty") }
        static var financialTwinDetails: String { l("dashboard.financial_twin.cta.details") }
        static var recentTitle: String      { l("dashboard.recent.title") }
        static var recentEmpty: String      { l("dashboard.recent.empty") }
    }

    // MARK: - Operations

    enum Operations {
        static var title: String            { l("operations.header.title") }
        static var addLabel: String         { l("operations.header.accessibility.add") }
        static var searchPlaceholder: String { l("operations.search.placeholder") }
        static var clearSearchLabel: String { l("operations.search.accessibility.clear") }
        static var filterAll: String        { l("operations.filter.all") }
        static var filterExpenses: String   { l("operations.filter.expenses") }
        static var filterIncome: String     { l("operations.filter.income") }
        static var presentationPickerLabel: String { l("operations.presentation.label") }
        static var presentationDaily: String { l("operations.presentation.daily") }
        static var presentationCalendar: String { l("operations.presentation.calendar") }
        static var presentationMonthly: String { l("operations.presentation.monthly") }
        static var balance: String          { l("operations.summary.balance") }
        static var previousMonth: String    { l("operations.calendar.accessibility.previous_month") }
        static var nextMonth: String        { l("operations.calendar.accessibility.next_month") }
        static func calendarDayBalance(_ date: String, _ balance: String) -> String {
            String(format: l("operations.calendar.accessibility.day_balance"), date, balance)
        }
        static var selectedDateEmptyTitle: String { l("operations.calendar.empty.title") }
        static var selectedDateEmptyMessage: String { l("operations.calendar.empty.message") }
        static var periodEmptyTitle: String { l("operations.period.empty.title") }
        static var periodEmptyMessage: String { l("operations.period.empty.message") }
        static var loading: String          { l("operations.list.loading") }
        static var loadErrorTitle: String   { l("operations.list.error.title") }
        static var emptyTitle: String       { l("operations.list.empty.title") }
        static var emptyMessage: String     { l("operations.list.empty.message") }
        static var emptyAddButton: String   { l("operations.list.empty.cta.add") }
        static var today: String            { l("operations.section.today") }
        static var yesterday: String        { l("operations.section.yesterday") }
        static func sectionExpenses(_ amount: String) -> String {
            String(format: l("operations.section.label.expenses"), amount)
        }
        static func sectionIncome(_ amount: String) -> String {
            String(format: l("operations.section.label.income"), amount)
        }
        static var deleteLabel: String      { l("operations.row.accessibility.delete") }
        static var deleteAction: String     { l("operations.row.action.delete") }
        static var deleteAlertTitle: String { l("operations.delete_alert.title") }
        static var deleteAlertOk: String    { l("operations.delete_alert.button.ok") }
        static var impulseLabel: String     { l("operations.row.accessibility.impulse") }
    }

    // MARK: - Add Operation

    enum AddOperation {
        static var titleNew: String            { l("add_operation.title.new") }
        static var titleEdit: String           { l("add_operation.title.edit") }
        static var sectionKind: String         { l("add_operation.section.kind") }
        static var sectionCategory: String     { l("add_operation.section.category") }
        static var sectionIncomeSource: String { l("add_operation.section.income_source") }
        static var sectionFundingSource: String { l("add_operation.section.funding_source") }
        static var sectionAmount: String       { l("add_operation.section.amount") }
        static var sectionDate: String         { l("add_operation.section.date") }
        static var categoryPlaceholder: String { l("add_operation.field.category.placeholder") }
        static var categoryTooLong: String     { l("add_operation.field.category.too_long") }
        static var createCategory: String      { l("add_operation.category.create") }
        static var selectCategory: String      { l("add_operation.category.select") }
        static var selectFundingSource: String { l("add_operation.funding_source.select") }
        static var fundingSourceHint: String   { l("add_operation.funding_source.hint") }
        static var dateLabel: String           { l("add_operation.field.date.label") }
        static var magicSection: String        { l("add_operation.magic.section") }
        static var magicPlaceholder: String    { l("add_operation.magic.placeholder") }
        static var magicButton: String         { l("add_operation.magic.accessibility.parse") }
        static var magicFailed: String         { l("add_operation.magic.error.failed") }
        static var merchantSection: String      { l("add_operation.merchant.section") }
        static var merchantPlaceholder: String  { l("add_operation.merchant.placeholder") }
        static var suggestedCategory: String    { l("add_operation.ml.suggested_category") }
        static var behaviorSection: String      { l("add_operation.behavior.section") }
        static var impulsePurchase: String      { l("add_operation.behavior.impulse") }
        static var impulseHint: String          { l("add_operation.behavior.impulse.hint") }
        static func mlCategory(_ id: String) -> String { l("add_operation.category.ml.\(id)") }

        static var defaultExpenseCategories: [String] {
            ["groceries", "food", "transport", "auto", "home", "health", "entertainment", "clothes"]
                .map { l("add_operation.category.default.\($0)") }
        }
        static var defaultIncomeCategories: [String] {
            ["salary", "bank_card", "credit_card", "current_account", "deposit", "freelance", "gift", "interest"]
                .map { l("add_operation.category.default.\($0)") }
        }
    }

    // MARK: - Financial Twin

    enum FinancialTwin {
        static var title: String { l("financial_twin.title") }
        static var privacy: String { l("financial_twin.privacy") }
        static var emptyTitle: String { l("financial_twin.empty.title") }
        static var emptyMessage: String { l("financial_twin.empty.message") }
        static var evidenceTitle: String { l("financial_twin.evidence.title") }
        static var methodTitle: String { l("financial_twin.method.title") }
        static var close: String { l("financial_twin.button.close") }
        static func sources(_ transactions: Int, _ budgets: Int, _ subscriptions: Int) -> String {
            String(format: l("financial_twin.sources"), transactions, budgets, subscriptions)
        }

        static var snapshotTitle: String { l("financial_twin.snapshot.title") }
        static func snapshotTopCategory(_ category: String, _ amount: String, _ currency: String, _ percent: Int) -> String {
            String(format: l("financial_twin.snapshot.headline.top_category"), category, amount, currency, percent)
        }
        static func snapshotBalance(_ balance: String, _ currency: String) -> String {
            String(format: l("financial_twin.snapshot.headline.balance"), balance, currency)
        }
        static func snapshotTotals(
            _ income: String,
            _ expenses: String,
            _ balance: String,
            _ currency: String,
            _ count: Int
        ) -> String {
            String(format: l("financial_twin.snapshot.evidence.totals"), income, currency, expenses, currency, balance, currency, count)
        }
        static var snapshotMethod: String { l("financial_twin.snapshot.method") }

        static var paydayTitle: String { l("financial_twin.payday.title") }
        static func paydayHeadline(_ category: String, _ percent: Int) -> String {
            String(format: l("financial_twin.payday.headline"), category, percent)
        }
        static func paydayComparison(_ count: Int, _ firstFive: String, _ baseline: String, _ currency: String) -> String {
            String(format: l("financial_twin.payday.evidence.comparison"), count, firstFive, currency, baseline, currency)
        }
        static func paydayDate(_ date: String) -> String {
            String(format: l("financial_twin.payday.evidence.date"), date)
        }
        static var paydayMethod: String { l("financial_twin.payday.method") }

        static var impulseTitle: String { l("financial_twin.impulse.title") }
        static func impulseHeadline(_ weekday: String, _ dayPart: String) -> String {
            String(format: l("financial_twin.impulse.headline"), weekday, dayPart)
        }
        static func impulseSummary(_ matching: Int, _ total: Int, _ amount: String, _ currency: String) -> String {
            String(format: l("financial_twin.impulse.evidence.summary"), matching, total, amount, currency)
        }
        static func impulseSample(_ date: String, _ amount: String, _ currency: String) -> String {
            String(format: l("financial_twin.impulse.evidence.sample"), date, amount, currency)
        }
        static func dayPart(_ value: FinancialTwinDayPart) -> String {
            l("financial_twin.impulse.day_part.\(value.rawValue)")
        }
        static var impulseMethod: String { l("financial_twin.impulse.method") }

        static var budgetTitle: String { l("financial_twin.budget.title") }
        static var budgetHeadline: String { l("financial_twin.budget.headline") }
        static func budgetCrossing(
            _ category: String,
            _ limit: String,
            _ date: String,
            _ spent: String,
            _ currency: String
        ) -> String {
            String(format: l("financial_twin.budget.evidence.crossing"), category, limit, currency, date, spent, currency)
        }
        static var budgetMethod: String { l("financial_twin.budget.method") }

        static var monthEndTitle: String { l("financial_twin.month_end.title") }
        static func monthEndHeadline(_ amount: String, _ currency: String) -> String {
            String(format: l("financial_twin.month_end.headline"), amount, currency)
        }
        static func monthEndSample(
            _ month: String,
            _ income: String,
            _ expenses: String,
            _ balance: String,
            _ currency: String
        ) -> String {
            String(format: l("financial_twin.month_end.evidence.sample"), month, income, expenses, balance, currency)
        }
        static var monthEndMethod: String { l("financial_twin.month_end.method") }

        static var recurringTitle: String { l("financial_twin.recurring.title") }
        static func recurringHeadline(_ name: String) -> String {
            String(format: l("financial_twin.recurring.headline"), name)
        }
        static func recurringSummary(_ name: String, _ amount: String, _ currency: String, _ count: Int) -> String {
            String(format: l("financial_twin.recurring.evidence.summary"), name, amount, currency, count)
        }
        static func recurringSample(_ date: String, _ amount: String, _ currency: String) -> String {
            String(format: l("financial_twin.recurring.evidence.sample"), date, amount, currency)
        }
        static var recurringMethod: String { l("financial_twin.recurring.method") }
    }

    // MARK: - Assistant

    enum Assistant {
        static var title: String              { l("assistant.header.title") }
        static var historyLabel: String       { l("assistant.header.accessibility.history") }
        static var intro: String              { l("assistant.intro") }
        static var noticeDownloading: String  { l("assistant.notice.downloading") }
        static var noticeUnavailable: String  { l("assistant.notice.unavailable") }
        static var suggestionWhereMoneyWent: String { l("assistant.suggestion.where_money_went") }
        static var suggestionHowToSave: String { l("assistant.suggestion.how_to_save") }
        static var suggestionEnoughUntilSalary: String { l("assistant.suggestion.enough_until_salary") }
        static var inputPlaceholder: String   { l("assistant.input.placeholder") }
        static var sendLabel: String          { l("assistant.input.accessibility.send") }
        static var thinking: String           { l("assistant.thinking") }
        static var errorInvalidQuestion: String { l("assistant.error.invalid_question") }
        static var errorNoData: String        { l("assistant.error.no_data") }
        static var errorCategoryNotFound: String { l("assistant.error.category_not_found") }
        static var errorGeneric: String       { l("assistant.error.generic") }
        static func categoryTotal(_ category: String, _ amount: String, _ currency: String) -> String {
            String(format: l("assistant.category_total.headline"), category, amount, currency)
        }
        static func categoryOperationCount(_ count: Int) -> String {
            String(format: l("assistant.category_total.operation_count"), count)
        }
        static func categoryAverage(_ amount: String, _ currency: String) -> String {
            String(format: l("assistant.category_total.average"), amount, currency)
        }
        static var savingsNeedsDetails: String { l("assistant.savings.needs_details") }
        static var savingsMissingDeadline: String { l("assistant.savings.missing_deadline") }
        static func savingsMissingDeadlineAndIncome(_ currency: String) -> String {
            String(format: l("assistant.savings.missing_deadline_and_income"), currency)
        }
        static func savingsCurrencyMismatch(_ target: String, _ data: String) -> String {
            String(format: l("assistant.savings.currency_mismatch"), target, data)
        }
        static func savingsMissingIncome(_ currency: String) -> String {
            String(format: l("assistant.savings.missing_income"), currency)
        }
        static func savingsReviewCategory(_ category: String, _ amount: String, _ currency: String) -> String {
            String(format: l("assistant.savings.review_category"), category, amount, currency)
        }
        static var chartOther: String         { l("assistant.chart.category.other") }
        static var chartTotal: String         { l("assistant.chart.label.total") }
        static func chartTotalExpenses(_ amount: String) -> String {
            String(format: l("assistant.chart.accessibility.total_expenses"), amount)
        }
    }

    // MARK: - Plan

    enum Plan {
        static var title: String            { l("plan.header.title") }
        static var calendarLabel: String    { l("plan.header.accessibility.calendar") }
        static var sectionPickerLabel: String { l("plan.section_picker.label") }
        static var sectionPayments: String  { l("plan.section.payments") }
        static var sectionBudgets: String   { l("plan.section.budgets") }
        static var sectionGoals: String     { l("plan.section.goals") }
        static var paymentsTitle: String    { l("plan.payments.title") }
        static var allPayments: String      { l("plan.payments.cta.all") }
        static var forecastTitle: String    { l("plan.forecast.title") }
        static var budgetsTitle: String     { l("plan.budgets.title") }
        static var budgetsAll: String       { l("plan.budgets.cta.all") }
        static func remaining(_ amount: String) -> String {
            String(format: l("plan.budgets.label.remaining"), amount)
        }
        static func placeholderTitle(_ section: String) -> String {
            String(format: l("plan.placeholder.title"), section)
        }
        static var placeholderMessage: String { l("plan.placeholder.message") }
        static var addSubscription: String { l("plan.subscription.accessibility.add") }
        static var subscriptionsEmptyTitle: String { l("plan.subscription.empty.title") }
        static var subscriptionsEmptyMessage: String { l("plan.subscription.empty.message") }
        static var deleteSubscription: String { l("plan.subscription.action.delete") }
        static var subscriptionTitleNew: String { l("plan.subscription.title.new") }
        static var subscriptionTitleEdit: String { l("plan.subscription.title.edit") }
        static var subscriptionSectionDetails: String { l("plan.subscription.section.details") }
        static var subscriptionSectionAmount: String { l("plan.subscription.section.amount") }
        static var subscriptionSectionDate: String { l("plan.subscription.section.date") }
        static var subscriptionNamePlaceholder: String { l("plan.subscription.field.name.placeholder") }
        static var subscriptionNameTooLong: String { l("plan.subscription.field.name.too_long") }
        static var subscriptionDateLabel: String { l("plan.subscription.field.date.label") }
        static var loadError: String { l("plan.error.load") }
        static var saveError: String { l("plan.subscription.error.save") }
        static var deleteError: String { l("plan.subscription.error.delete") }
        static var addBudget: String { l("plan.budget.accessibility.add") }
        static var budgetEmptyTitle: String { l("plan.budget.empty.title") }
        static var budgetEmptyMessage: String { l("plan.budget.empty.message") }
        static var deleteBudget: String { l("plan.budget.action.delete") }
        static var budgetTitleNew: String { l("plan.budget.title.new") }
        static var budgetTitleEdit: String { l("plan.budget.title.edit") }
        static var budgetSectionCategory: String { l("plan.budget.section.category") }
        static var budgetSectionLimit: String { l("plan.budget.section.limit") }
        static var budgetMonthlyHint: String { l("plan.budget.field.limit.hint") }
        static var budgetDuplicateCategory: String { l("plan.budget.error.duplicate_category") }
        static var budgetSaveError: String { l("plan.budget.error.save") }
        static var budgetDeleteError: String { l("plan.budget.error.delete") }
        static var budgetPaceOnTrack: String { l("plan.budget.pace.on_track") }
        static var budgetPaceAtRisk: String { l("plan.budget.pace.at_risk") }
        static var budgetPaceOver: String { l("plan.budget.pace.over") }
        static func budgetMonthTitle(_ month: String) -> String {
            String(format: l("plan.budget.summary.month"), month)
        }
        static func budgetSpentOf(_ spent: String, _ limit: String) -> String {
            String(format: l("plan.budget.summary.spent_of"), spent, limit)
        }
        static func budgetPerDay(_ amount: String) -> String {
            String(format: l("plan.budget.summary.per_day"), amount)
        }
        static func budgetProjected(_ amount: String) -> String {
            String(format: l("plan.budget.summary.projected"), amount)
        }
        static func budgetOverBy(_ amount: String) -> String {
            String(format: l("plan.budget.summary.over_by"), amount)
        }
        static func unbudgetedSpending(_ amount: String) -> String {
            String(format: l("plan.budget.summary.unbudgeted"), amount)
        }
        static var addGoal: String { l("plan.goal.accessibility.add") }
        static var goalEmptyTitle: String { l("plan.goal.empty.title") }
        static var goalEmptyMessage: String { l("plan.goal.empty.message") }
        static var goalCreate: String { l("plan.goal.empty.cta.create") }
        static var goalsTitle: String { l("plan.goal.summary.title") }
        static func goalSavedOf(_ saved: String, _ target: String) -> String {
            String(format: l("plan.goal.summary.saved_of"), saved, target)
        }
        static func goalMonthlyPlan(_ amount: String) -> String {
            String(format: l("plan.goal.summary.monthly_plan"), amount)
        }
        static func goalHistoricalSurplus(_ amount: String) -> String {
            String(format: l("plan.goal.summary.historical_surplus"), amount)
        }
        static var goalPlanComplete: String { l("plan.goal.summary.health.complete") }
        static var goalPlanFeasible: String { l("plan.goal.summary.health.feasible") }
        static var goalPlanNoHistory: String { l("plan.goal.summary.health.no_history") }
        static var goalPlanOverdue: String { l("plan.goal.summary.health.overdue") }
        static func goalPlanGap(_ amount: String) -> String {
            String(format: l("plan.goal.summary.health.gap"), amount)
        }
        static func goalPerMonth(_ amount: String) -> String {
            String(format: l("plan.goal.card.per_month"), amount)
        }
        static func editGoal(_ name: String) -> String {
            String(format: l("plan.goal.accessibility.edit"), name)
        }
        static var goalUpdateProgress: String { l("plan.goal.action.update_progress") }
        static var deleteGoal: String { l("plan.goal.action.delete") }
        static var goalStateActive: String { l("plan.goal.state.active") }
        static var goalStateOverdue: String { l("plan.goal.state.overdue") }
        static var goalStateComplete: String { l("plan.goal.state.complete") }
        static var goalTitleNew: String { l("plan.goal.title.new") }
        static var goalTitleEdit: String { l("plan.goal.title.edit") }
        static var goalSectionDetails: String { l("plan.goal.section.details") }
        static var goalSectionAmounts: String { l("plan.goal.section.amounts") }
        static var goalSectionDeadline: String { l("plan.goal.section.deadline") }
        static var goalNamePlaceholder: String { l("plan.goal.field.name.placeholder") }
        static var goalNameTooLong: String { l("plan.goal.field.name.too_long") }
        static var goalTargetAmount: String { l("plan.goal.field.target_amount") }
        static var goalSavedAmount: String { l("plan.goal.field.saved_amount") }
        static var goalTargetDate: String { l("plan.goal.field.target_date") }
        static func goalEditorMonthly(_ amount: String) -> String {
            String(format: l("plan.goal.editor.monthly_hint"), amount)
        }
        static var goalContributionTitle: String { l("plan.goal.contribution.title") }
        static var goalContributionCurrent: String { l("plan.goal.contribution.section.current") }
        static var goalContributionAction: String { l("plan.goal.contribution.section.action") }
        static var goalContributionAdd: String { l("plan.goal.contribution.action.add") }
        static var goalContributionWithdraw: String { l("plan.goal.contribution.action.withdraw") }
        static var goalContributionAmount: String { l("plan.goal.contribution.field.amount") }
        static var goalContributionInsufficient: String { l("plan.goal.contribution.error.insufficient") }
        static var goalSaveError: String { l("plan.goal.error.save") }
        static var goalDeleteError: String { l("plan.goal.error.delete") }
        static var goalIconEmergency: String { l("plan.goal.icon.emergency") }
        static var goalIconTravel: String { l("plan.goal.icon.travel") }
        static var goalIconHome: String { l("plan.goal.icon.home") }
        static var goalIconCar: String { l("plan.goal.icon.car") }
        static var goalIconEducation: String { l("plan.goal.icon.education") }
        static var goalIconOther: String { l("plan.goal.icon.other") }
    }

    // MARK: - Settings

    enum Settings {
        static var title: String            { l("settings.title") }
        static var sectionAccount: String   { l("settings.section.account") }
        static var sectionAppearance: String { l("settings.section.appearance") }
        static var sectionNotifications: String { l("settings.section.notifications") }
        static var sectionSecurity: String  { l("settings.section.security") }
        static var sectionData: String      { l("settings.section.data") }
        static var sectionAbout: String     { l("settings.section.about") }
        static var profile: String          { l("settings.row.profile") }
        static var currency: String         { l("settings.row.currency") }
        static var language: String         { l("settings.row.language") }
        static func languageName(_ code: String) -> String { l("settings.row.language.\(code)") }
        static var theme: String            { l("settings.row.theme") }
        static var themeLight: String       { l("settings.row.theme.light") }
        static var themeDark: String        { l("settings.row.theme.dark") }
        static var accent: String           { l("settings.row.accent") }
        static var accentValue: String      { l("settings.row.accent.value") }
        static var reminders: String        { l("settings.row.reminders") }
        static var weeklySummary: String    { l("settings.row.weekly_summary") }
        static var faceID: String           { l("settings.row.face_id") }
        static var passcode: String         { l("settings.row.passcode") }
        static var exportData: String       { l("settings.row.export") }
        static var backup: String           { l("settings.row.backup") }
        static var rateApp: String          { l("settings.row.rate") }
        static var writeFeedback: String    { l("settings.row.feedback") }
        static func version(_ version: String) -> String {
            String(format: l("settings.version"), version)
        }
        static var placeholderMessage: String { l("settings.placeholder.message") }
    }

    // MARK: - New Category

    enum NewCategory {
        static var title: String                  { l("new_category.title") }
        static var editTitle: String              { l("new_category.title.edit") }
        static var kindPickerLabel: String        { l("new_category.kind_picker.label") }
        static var nameLabel: String              { l("new_category.field.name.label") }
        static var namePlaceholder: String        { l("new_category.field.name.placeholder") }
        static var colorLabel: String             { l("new_category.field.color.label") }
        static var iconLabel: String              { l("new_category.field.icon.label") }
        static var selectIconLabel: String        { l("new_category.field.icon.accessibility.select") }
        static func editAction(_ name: String) -> String {
            String(format: l("new_category.action.edit"), name)
        }
        static var descriptionLabel: String       { l("new_category.field.description.label") }
        static var descriptionPlaceholder: String { l("new_category.field.description.placeholder") }
        static func color(_ id: String) -> String { l("new_category.color.\(id)") }
    }

    // MARK: - Private helpers

    private static func l(_ key: String) -> String {
        LocalizationManager.shared.localizedString(for: key)
    }
}
