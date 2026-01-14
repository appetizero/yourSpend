import SwiftUI
import SwiftData

// MARK: - 主入口 TabView
struct ContentView: View {
    @State private var selection = 0
    
    // ✅ 修复 1：新增设置页面的导航路径状态
    @State private var settingsPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selection) {
            
            // Tab 1: 记账
            RecordView()
                .tabItem {
                    // 使用 Time2Go 风格的图标逻辑
                    Image(systemName: "square.and.pencil")
                    Text("记录")
                }
                .tag(0)
            
            // Tab 2: 统计
            DashboardView() // 确保你项目里有 DashboardView.swift
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("统计")
                }
                .tag(1)
            
            // Tab 3: 设置
            // ✅ 修复 2：这里必须传入 path 参数
            SettingsView(path: $settingsPath)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(2)
        }
        // Tint color 设置为 Primary，配合 TabBarAppearance 使用
        .tint(.primary)
        // ✅ 可选优化：每次切到设置页时，如果需要重置页面，可以在这里处理
        .onChange(of: selection) { _, newValue in
            // 如果你希望每次点“设置”都回到设置主页，可以取消下面注释
            // if newValue == 2 { settingsPath = NavigationPath() }
        }
    }
}

// MARK: - 记账页面 (Time2Go 风格化)
struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var inputAmount: String = "0"
    @State private var selectedCategory: Category = .food
    @State private var selectedDate: Date = Date()
    @State private var note: String = ""
    
    @State private var showDatePicker: Bool = false
    @State private var showNoteInput: Bool = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // 1. Header Section
                VStack(spacing: 16) {
                    Text("记一笔")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)
                    
                    // 分类胶囊
                    Menu {
                        ForEach(Category.allCases) { category in
                            Button(action: { selectedCategory = category }) {
                                Label(category.rawValue, systemImage: category.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedCategory.icon)
                                .font(.system(size: 18, weight: .semibold))
                            Text(selectedCategory.rawValue)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer(minLength: 20)
                
                // 2. Center Section (Amount Display)
                VStack(spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("¥")
                            .font(.system(size: 40, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Text(inputAmount)
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 24)
                    
                    // 日期和备注的小按钮
                    HStack(spacing: 16) {
                        Button(action: { showDatePicker = true }) {
                            Label(formatDateButton(selectedDate), systemImage: "calendar")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isDateToday(selectedDate) ? .secondary : .primary)
                        
                        Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1, height: 16)
                        
                        Button(action: { showNoteInput = true }) {
                            Label(note.isEmpty ? "添加备注" : note, systemImage: note.isEmpty ? "pencil" : "pencil.circle.fill")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(note.isEmpty ? .secondary : .primary)
                    }
                }
                
                Spacer(minLength: 20)
                
                // 3. Bottom Section
                VStack(spacing: 24) {
                    Divider()
                        .padding(.horizontal, 40)
                        .opacity(0.3)
                    
                    // 键盘
                    KeypadView(input: $inputAmount)
                        .padding(.horizontal, 40)
                    
                    // 主操作按钮 (需要 Components.swift 里的 PrimaryButton)
                    PrimaryButton(
                        title: "确认保存",
                        icon: "arrow.up.circle.fill",
                        isEnabled: Double(inputAmount) ?? 0 > 0
                    ) {
                        saveTransaction()
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                PrimaryButton(title: "确定") { showDatePicker = false }
                    .padding()
            }
            .presentationDetents([.medium])
        }
        .alert("添加备注", isPresented: $showNoteInput) {
            TextField("输入备注...", text: $note)
            Button("确定", role: .cancel) {}
        }
    }
    
    // --- Logic ---
    private func saveTransaction() {
        guard let amount = Double(inputAmount), amount > 0 else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let newTransaction = Transaction(
            timestamp: selectedDate,
            amount: amount,
            category: selectedCategory,
            note: note
        )
        modelContext.insert(newTransaction)
        
        inputAmount = "0"
        note = ""
        selectedDate = Date()
    }
    
    func formatDateButton(_ date: Date) -> String {
        Calendar.current.isDateInToday(date) ? "今天" : DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
    }
    
    func isDateToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Keypad Component
struct KeypadView: View {
    @Binding var input: String
    let columns = Array(repeating: GridItem(.flexible()), count: 3)
    let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "delete"]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(keys, id: \.self) { key in
                Button(action: { handleTap(key) }) {
                    Circle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(height: 72)
                        .overlay(
                            Group {
                                if key == "delete" {
                                    Image(systemName: "delete.left.fill")
                                        .font(.title3)
                                } else {
                                    Text(key)
                                        .font(.title2.weight(.medium))
                                }
                            }
                            .foregroundStyle(.primary)
                        )
                }
                .buttonStyle(KeypadButtonStyle())
            }
        }
    }
    
    func handleTap(_ key: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        if key == "delete" {
            if input.count > 1 { input.removeLast() } else { input = "0" }
        } else {
            if input == "0" && key != "." { input = key }
            else if input.count < 9 { input += key }
        }
    }
}

struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
