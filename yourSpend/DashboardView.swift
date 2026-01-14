import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) var modelContext
    
    // 查询数据
    @Query(sort: \Transaction.timestamp, order: .reverse) var transactions: [Transaction]
    
    // 状态：当前选中的时间段（预留给未来功能）
    @State private var selectedPeriod: String = "本月"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // --- A. 统计图表 ---
                    VStack(alignment: .leading, spacing: 10) {
                        Text("本月支出")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if transactions.isEmpty {
                            ContentUnavailableView("暂无数据", systemImage: "chart.pie")
                                .frame(height: 200)
                        } else {
                            Chart(categoryTotals, id: \.category) { item in
                                SectorMark(
                                    angle: .value("Amount", item.amount),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2.0
                                )
                                .cornerRadius(5)
                                .foregroundStyle(by: .value("Category", item.category.rawValue))
                            }
                            .frame(height: 220)
                            .padding(.horizontal)
                            .chartLegend(position: .bottom)
                        }
                    }
                    
                    Divider().padding()
                    
                    // --- B. 流水列表 ---
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                            Section {
                                ForEach(groupedTransactions[date]!) { transaction in
                                    TransactionRow(transaction: transaction)
                                }
                            } header: {
                                HStack {
                                    Text(formatDateHeader(date))
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("¥\(dayTotal(for: date), specifier: "%.2f")")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                                .background(Color(UIColor.systemBackground))
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // --- 数据逻辑 (保持不变) ---
    var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.timestamp)
        }
    }
    
    var categoryTotals: [(category: Category, amount: Double)] {
        var totals: [Category: Double] = [:]
        for t in transactions {
            totals[t.category, default: 0] += t.amount
        }
        return totals.map { ($0.key, $0.value) }.sorted { $0.amount > $1.amount }
    }
    
    func dayTotal(for date: Date) -> Double {
        groupedTransactions[date]?.reduce(0) { $0 + $1.amount } ?? 0
    }
    
    func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInYesterday(date) { return "昨天" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date)
    }
}

// TransactionRow 组件 (保持不变)
struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        HStack {
            ZStack {
                Circle().fill(Color.gray.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: transaction.category.icon).foregroundStyle(.primary)
            }
            VStack(alignment: .leading) {
                Text(transaction.category.rawValue).font(.body)
                if !transaction.note.isEmpty {
                    Text(transaction.note).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("- ¥\(transaction.amount, specifier: "%.2f")")
                .font(.system(.body, design: .rounded)).fontWeight(.bold)
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
}
