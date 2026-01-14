import SwiftUI
import SwiftData
import Charts

// MARK: - Date Granularity Logic
enum DateGranularity: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year
    case custom
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .day: return String(localized: "stats.range.day")
        case .week: return String(localized: "stats.range.week")
        case .month: return String(localized: "stats.range.month")
        case .year: return String(localized: "stats.range.year")
        case .custom: return String(localized: "stats.range.custom")
        }
    }
    
    var icon: String {
        switch self {
        case .day: return "sun.max"
        case .week: return "calendar.day.timeline.left"
        case .month: return "calendar"
        case .year: return "archivebox"
        case .custom: return "pencil.and.outline"
        }
    }
}

// MARK: - Components: Date Filter
struct DateFilterView: View {
    @Binding var granularity: DateGranularity
    @Binding var anchorDate: Date
    @Binding var customStart: Date
    @Binding var customEnd: Date
    
    @State private var showCalendarSheet = false
    
    // Temp vars for custom range picker
    @State private var tempStart: Date = Date()
    @State private var tempEnd: Date = Date()
    
    private var calendar: Calendar { Calendar.current }
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Navigation Area (Page Turner OR Custom Button)
            if granularity == .custom {
                // Custom Range Button
                Button {
                    tempStart = customStart
                    tempEnd = customEnd
                    showCalendarSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Text(formatCustomRange(start: customStart, end: customEnd))
                            .font(.system(size: 15, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                // Navigator (< Date >)
                HStack(spacing: 20) {
                    // Left Arrow (Past)
                    Button {
                        navigate(direction: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Date Label
                    Text(getDateLabel())
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .frame(minWidth: 120)
                        .multilineTextAlignment(.center)
                        .id(anchorDate)

                    // Right Arrow (Future)
                    Button {
                        navigate(direction: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.medium))
                            .foregroundStyle(canNavigateForward ? .secondary : .quaternary) // Dim if disabled
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canNavigateForward)
                }
                .padding(.horizontal, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 5)
        .padding(.top, 12)
        .padding(.bottom, granularity == .custom ? 0 : 4)
        
        // Custom Calendar Sheet
        .sheet(isPresented: $showCalendarSheet) {
            NavigationStack {
                CalendarRangePicker(startDate: $tempStart, endDate: $tempEnd)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(String(localized: "common.cancel")) { showCalendarSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "common.done")) {
                                customStart = tempStart
                                customEnd = tempEnd
                                showCalendarSheet = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Logic
    
    private var canNavigateForward: Bool {
        let now = Date()
        switch granularity {
        case .day:
            return !calendar.isDateInToday(anchorDate) && anchorDate < now
        case .week:
            return !calendar.isDate(anchorDate, equalTo: now, toGranularity: .weekOfYear) && anchorDate < now
        case .month:
            return !calendar.isDate(anchorDate, equalTo: now, toGranularity: .month) && anchorDate < now
        case .year:
            return !calendar.isDate(anchorDate, equalTo: now, toGranularity: .year) && anchorDate < now
        case .custom:
            return false
        }
    }
    
    private func navigate(direction: Int) {
        let component: Calendar.Component
        let value = direction
        
        switch granularity {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        default: return
        }
        
        if let newDate = calendar.date(byAdding: component, value: value, to: anchorDate) {
            anchorDate = newDate
        }
    }
    
    // Label Logic
    private func getDateLabel() -> String {
        let formatter = DateFormatter()
        
        switch granularity {
        case .day:
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: anchorDate)
            
        case .week:
            var gregorian = Calendar(identifier: .gregorian)
            gregorian.firstWeekday = 2
            let interval = gregorian.dateInterval(of: .weekOfYear, for: anchorDate)!
            let end = gregorian.date(byAdding: .day, value: -1, to: interval.end)!
            
            formatter.dateFormat = "MM/dd"
            return "\(formatter.string(from: interval.start)) - \(formatter.string(from: end))"
            
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: anchorDate)
            
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: anchorDate)
            
        case .custom:
            return ""
        }
    }
    
    private func formatCustomRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        if calendar.isDate(start, inSameDayAs: end) {
            return formatter.string(from: start)
        } else {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

// MARK: - Main View
struct DashboardView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Transaction.timestamp, order: .reverse) var transactions: [Transaction]
    
    // Config
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "CNY"
    @AppStorage("showUnifiedCurrency") private var showUnified: Bool = false
    
    // New Filter State
    @State private var granularity: DateGranularity = .day
    @State private var anchorDate: Date = Date()
    @State private var customStart: Date = Date()
    @State private var customEnd: Date = Date()
    
    @State private var editingTransaction: Transaction?
    @State private var showScopeSheet = false

    // Calculated Range for Filtering
    var currentRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.firstWeekday = 2 // Monday start
        
        switch granularity {
        case .day:
            let start = calendar.startOfDay(for: anchorDate)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: anchorDate) ?? anchorDate
            return (start, end)
        case .week:
            guard let interval = gregorian.dateInterval(of: .weekOfYear, for: anchorDate) else { return (Date(), Date()) }
            return (interval.start, interval.end.addingTimeInterval(-1))
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: anchorDate) else { return (Date(), Date()) }
            return (interval.start, interval.end.addingTimeInterval(-1))
        case .year:
            guard let interval = calendar.dateInterval(of: .year, for: anchorDate) else { return (Date(), Date()) }
            return (interval.start, interval.end.addingTimeInterval(-1))
        case .custom:
            let start = calendar.startOfDay(for: customStart)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: customEnd) ?? customEnd
            return (start, end)
        }
    }

    var filteredTransactions: [Transaction] {
        let range = currentRange
        return transactions.filter { t in
            t.timestamp >= range.start && t.timestamp <= range.end
        }
    }
    
    var totalsByCurrency: [String: Double] {
        var totals: [String: Double] = [:]
        for t in filteredTransactions {
            totals[t.currency, default: 0] += t.amount
        }
        return totals
    }
    
    var unifiedTotal: Double {
        filteredTransactions.reduce(0) { partialResult, t in
            let converted = ExchangeRateManager.shared.convert(
                amount: t.amount,
                from: t.currency,
                to: defaultCurrencyCode
            )
            return partialResult + converted
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // 1. Header (Title + Granularity Switcher)
                HStack(alignment: .center) {
                    Text(String(localized: "tab.stats"))
                        .font(.system(size: 24, weight: .bold))
                    
                    Spacer()
                    
                    // Granularity Switcher
                    Button(action: { showScopeSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            Text(granularity.localizedName)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 60)
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                .background(Color(UIColor.systemBackground))
                
                // 2. Date Filter
                DateFilterView(
                    granularity: $granularity,
                    anchorDate: $anchorDate,
                    customStart: $customStart,
                    customEnd: $customEnd
                )
                .background(Color(UIColor.systemBackground))
                .zIndex(1)

                // A. Toggle
                HStack {
                    if showUnified {
                        Text("\(String(localized: "stats.unified_currency")) (\(defaultCurrencyCode))")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                    } else {
                        Text(String(localized: "stats.by_original_currency"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $showUnified)
                        .labelsHidden()
                        .tint(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal, 30)
                .padding(.top, 10)
                .background(Color(UIColor.systemBackground))

                // 3. Body
                ScrollView {
                    VStack(spacing: 0) {
                        // B. Total Amount Card
                        VStack(spacing: 15) {
                            if filteredTransactions.isEmpty {
                                summaryCard(
                                    currency: defaultCurrencyCode,
                                    amount: 0.00,
                                    showChartButton: true,
                                    currencyFilter: nil
                                )
                            } else {
                                if showUnified {
                                    summaryCard(
                                        currency: defaultCurrencyCode,
                                        amount: unifiedTotal,
                                        showChartButton: true,
                                        currencyFilter: nil
                                    )
                                } else {
                                    ForEach(totalsByCurrency.keys.sorted(), id: \.self) { currencyCode in
                                        let amount = totalsByCurrency[currencyCode] ?? 0
                                        summaryCard(
                                            currency: currencyCode,
                                            amount: amount,
                                            showChartButton: true,
                                            currencyFilter: currencyCode
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 15)
                        
                        // C. Transaction Flow
                        FlowListView(transactions: filteredTransactions, onEdit: { t in
                            editingTransaction = t
                        })
                        
                    }
                    .padding(.bottom, 80)
                }
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationTitle("")
            
            // Granularity Sheet
            .sheet(isPresented: $showScopeSheet) {
                VStack(spacing: 0) {
                    Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 36, height: 5).padding(.top, 10).padding(.bottom, 20)
                    Text(String(localized: "stats.select_view")).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary).padding(.bottom, 10)
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(DateGranularity.allCases) { type in
                                Button {
                                    granularity = type
                                    anchorDate = Date()
                                    showScopeSheet = false
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: type.icon).font(.headline).foregroundStyle(.primary).frame(width: 24)
                                        Text(type.localizedName).font(.headline).foregroundStyle(.primary)
                                        Spacer()
                                        if granularity == type { Image(systemName: "checkmark").font(.headline).foregroundStyle(.primary) }
                                    }
                                    .padding(.vertical, 16).padding(.horizontal, 20).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                if type != .custom { Divider().padding(.horizontal, 20) }
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
            }
            .sheet(item: $editingTransaction) { transaction in
                EditTransactionSheet(transaction: transaction)
            }
        }
    }
    
    // Helper View for the Total Card
    @ViewBuilder
    func summaryCard(currency: String, amount: Double, showChartButton: Bool, currencyFilter: String?) -> some View {
        let symbol = ExchangeRateManager.shared.getSymbol(for: currency)
        
        VStack(spacing: 10) {
            Text(currency)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .firstTextBaseline) {
                // Symbol + Amount
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(symbol)
                        .font(.system(size: 25, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", amount))
                        .font(.system(size: 25, weight: .medium, design: .monospaced))
                }
                
                Spacer()
                
                // Chart Button
                if showChartButton {
                    NavigationLink(destination: ChartsView(transactions: filteredTransactions, currencyFilter: currencyFilter)) {
                        HStack(spacing: 6) {
                            Text(String(localized: "stats.charts"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chart.bar.xaxis")
                                .font(.subheadline)
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color(UIColor.tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal, 30)
    }
}

// MARK: - Subview: Flow List
struct FlowListView: View {
    let transactions: [Transaction]
    var onEdit: (Transaction) -> Void
    
    var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.timestamp)
        }
    }
    
    var body: some View {
        if transactions.isEmpty {
            ContentUnavailableView(String(localized: "stats.no_transactions"), systemImage: "list.bullet.rectangle")
                .padding(.top, 40)
        } else {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                    Section(header:
                        Text(formatDateHeader(date))
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 30)
                            .background(Color(UIColor.systemBackground))
                    ) {
                        ForEach(groupedTransactions[date]!) { transaction in
                            TransactionRow(transaction: transaction)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 15)
                                .onTapGesture {
                                    onEdit(transaction)
                                }
                                .contextMenu {
                                    Button {
                                        onEdit(transaction)
                                    } label: {
                                        Label(String(localized: "common.edit"), systemImage: "pencil")
                                    }
                                }
                            Divider().padding(.leading, 65)
                        }
                    }
                    .padding(.bottom, 25)
                }
            }
        }
    }
    
    func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if Calendar.current.isDateInToday(date) { return String(localized: "common.today") }
        if Calendar.current.isDateInYesterday(date) { return String(localized: "common.yesterday") }
        return formatter.string(from: date)
    }
}

// MARK: - Subview: Charts (Secondary Page)
struct ChartsView: View {
    let transactions: [Transaction]
    let currencyFilter: String?
    
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "CNY"
    @AppStorage("showUnifiedCurrency") private var showUnified: Bool = false
    
    struct ChartGroupKey: Hashable {
        let categoryID: String
        let categoryName: String
        let categoryIcon: String
        let currency: String
    }
    
    struct ChartItem: Identifiable {
        var id: ChartGroupKey { key }
        let key: ChartGroupKey
        let displayAmount: Double
        let normalizedAmount: Double
        let percentage: Double
    }
    
    private var effectiveTransactions: [Transaction] {
        if let filter = currencyFilter {
            return transactions.filter { $0.currency == filter }
        }
        return transactions
    }
    
    private var isUnifiedMode: Bool {
        if currencyFilter != nil { return false }
        return showUnified
    }
    
    var chartData: [ChartItem] {
        let sourceData = effectiveTransactions
        let grouped = Dictionary(grouping: sourceData) { t in
            if isUnifiedMode {
                return ChartGroupKey(
                    categoryID: t.categoryModel.id,
                    categoryName: t.categoryModel.name,
                    categoryIcon: t.categoryModel.icon,
                    currency: defaultCurrencyCode
                )
            } else {
                return ChartGroupKey(
                    categoryID: t.categoryModel.id,
                    categoryName: t.categoryModel.name,
                    categoryIcon: t.categoryModel.icon,
                    currency: t.currency
                )
            }
        }
        
        let totalPurchasingPower = sourceData.reduce(0) { sum, t in
            sum + ExchangeRateManager.shared.convert(amount: t.amount, from: t.currency, to: defaultCurrencyCode)
        }
        
        return grouped.map { (key, values) in
            let displaySum: Double
            if isUnifiedMode {
                displaySum = values.reduce(0) { sum, t in
                    sum + ExchangeRateManager.shared.convert(amount: t.amount, from: t.currency, to: defaultCurrencyCode)
                }
            } else {
                displaySum = values.reduce(0) { sum, t in sum + t.amount }
            }
            
            let normalizedSum = values.reduce(0) { sum, t in
                sum + ExchangeRateManager.shared.convert(amount: t.amount, from: t.currency, to: defaultCurrencyCode)
            }
            
            let percent = totalPurchasingPower > 0 ? (normalizedSum / totalPurchasingPower) : 0
            
            return ChartItem(
                key: key,
                displayAmount: displaySum,
                normalizedAmount: normalizedSum,
                percentage: percent
            )
        }
        .sorted { $0.normalizedAmount > $1.normalizedAmount }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                
                // Info Header
                HStack {
                    if isUnifiedMode {
                        Text("\(String(localized: "stats.unified_view")) (\(defaultCurrencyCode))")
                    } else {
                        if let filter = currencyFilter {
                            Text("\(filter) \(String(localized: "stats.breakdown"))")
                        } else {
                            Text(String(localized: "stats.original_currency_view"))
                        }
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 30)
                .padding(.top, 20)

                if effectiveTransactions.isEmpty {
                    ContentUnavailableView(String(localized: "stats.chart_no_data"), systemImage: "chart.bar")
                        .padding(.top, 56)
                } else {
                    // Chart
                    Chart {
                        ForEach(Array(chartData.enumerated()), id: \.element.key) { index, item in
                            BarMark(
                                x: .value("Category", item.key.categoryName),
                                y: .value("Amount", item.normalizedAmount)
                            )
                            .foregroundStyle(
                                getGrayscaleColor(index: index, total: chartData.count)
                            )
                            .cornerRadius(6)
                            .annotation(position: .top, spacing: 5) {
                                Text(String(format: "%.0f%%", item.percentage * 100))
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .chartXAxis {
                        AxisMarks(preset: .aligned, values: .automatic) {
                            AxisValueLabel()
                            .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic) { _ in }
                    }
                    .frame(height: 220)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                    
                    // Legend List
                    VStack(spacing: 20) {
                        ForEach(Array(chartData.enumerated()), id: \.element.key) { index, item in
                            HStack(spacing: 15) {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: item.key.categoryIcon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.key.categoryName)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    
                                    Text(String(format: "%.1f%%", item.percentage * 100))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                let symbol = ExchangeRateManager.shared.getSymbol(for: item.key.currency)
                                Text("\(symbol) \(String(format: "%.2f", item.displayAmount))")
                                    .font(.body.monospaced())
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 30)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(String(localized: "stats.charts"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func getGrayscaleColor(index: Int, total: Int) -> Color {
        let count = Double(max(total, 1))
        let position = Double(index)
        let opacity = 0.2 + (position / count) * 0.8
            
        return Color.primary.opacity(max(opacity, 0.1))
    }
}

// MARK: - Components (Unchanged)

struct TransactionRow: View {
    let transaction: Transaction
    
    var currencySymbol: String {
        ExchangeRateManager.shared.getSymbol(for: transaction.currency)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.categoryModel.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.categoryModel.name)
                    .font(.body.weight(.medium))
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(currencySymbol) \(String(format: "%.2f", transaction.amount))")
                .font(.body.monospaced())
        }
        .padding(.horizontal)
    }
}

struct EditTransactionSheet: View {
    @Bindable var transaction: Transaction
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @ObservedObject var categoryManager = CategoryManager.shared
    
    @State private var showCurrencyPicker = false
    
    var currencySymbol: String {
        ExchangeRateManager.shared.getSymbol(for: transaction.currency)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. Date and Amount
                Section {
                    DatePicker(
                        selection: $transaction.timestamp,
                        displayedComponents: .date
                    ) {
                        Text(String(localized: "record.select_date"))
                    }
                    .tint(.primary)
                    
                    HStack {
                        Text(String(localized: "record.edit_amount"))
                        Spacer()
                        
                        // Currency + Input
                        HStack(spacing: 8) {
                            Button {
                                showCurrencyPicker = true
                            } label: {
                                HStack(spacing: 2) {
                                    Text(currencySymbol)
                                        .foregroundStyle(.primary)
                                        .fontWeight(.medium)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)

                            TextField("0.00", value: $transaction.amount, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
                
                // 2. Category
                Section {
                    Picker(selection: $transaction.categoryRawValue) {
                        ForEach(categoryManager.categories) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                    .foregroundStyle(.primary)
                                Text(cat.name)
                            }
                            .tag(cat.id)
                        }
                    } label: {
                        Text(String(localized: "record.edit_category"))
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // 3. Note
                Section {
                    HStack {
                        Text(String(localized: "record.edit_note"))
                        Spacer()
                        TextField(String(localized: "record.add_note"), text: $transaction.note)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // 4. Delete
                Section {
                    Button(role: .destructive) {
                        modelContext.delete(transaction)
                        dismiss()
                    } label: {
                        Text(String(localized: "common.delete"))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(String(localized: "record.edit_transaction"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                        .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done")) { dismiss() }
                        .foregroundStyle(.primary)
                }
            }
            .sheet(isPresented: $showCurrencyPicker) {
                NavigationStack {
                    CurrencyPickerView(selectedCurrency: $transaction.currency)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(String(localized: "common.done")) {
                                    showCurrencyPicker = false
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                }
                .presentationDetents([.medium])
            }
        }
        .presentationDetents([.medium, .large])
        .tint(.primary)
    }
}

// MARK: - Preview
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Transaction.self, configurations: config)
        
        let samples = [
            Transaction(timestamp: Date(), amount: 35.00, categoryID: "food", note: "午餐", currency: "CNY"),
            Transaction(timestamp: Date().addingTimeInterval(-3600), amount: 18.00, categoryID: "drink", note: "奶茶", currency: "USD"),
            Transaction(timestamp: Date().addingTimeInterval(-86400), amount: 45.00, categoryID: "transport", note: "Taxi", currency: "GBP"),
            Transaction(timestamp: Date().addingTimeInterval(-172800), amount: 299.00, categoryID: "wear", note: "T恤", currency: "CNY")
        ]
        
        for item in samples {
            container.mainContext.insert(item)
        }
        
        return DashboardView()
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
