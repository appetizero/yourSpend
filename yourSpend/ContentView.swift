import SwiftUI
import SwiftData

// MARK: - 主入口 TabView
struct ContentView: View {
    @State private var selection = 0
    @State private var settingsPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selection) {
            // Tab 1: 记账
            RecordView(tabSelection: $selection, settingsPath: $settingsPath)
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text(String(localized: "tab.record"))
                }
                .tag(0)
            
            // Tab 2: 统计
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text(String(localized: "tab.stats"))
                }
                .tag(1)
            
            // Tab 3: 设置
            SettingsView(path: $settingsPath)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(String(localized: "tab.settings"))
                }
                .tag(2)
        }
        .tint(.primary)
    }
}

// MARK: - 记账页面
struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var tabSelection: Int
    @Binding var settingsPath: NavigationPath
    
    @State private var inputAmount: String = "0"
    @State private var selectedCategoryID: String = "food"
    @State private var selectedDate: Date = Date()
    @State private var note: String = ""
    
    @State private var showDatePicker: Bool = false
    @State private var showNoteInput: Bool = false
    @State private var showCategorySheet: Bool = false
    @State private var showCurrencySheet: Bool = false
    @State private var showSuccessToast: Bool = false
    
    @AppStorage("currencyCode") private var currencyCode: String = "CNY"
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "CNY"
    
    @ObservedObject var categoryManager = CategoryManager.shared
    
    let currencies: [Currency] = [
        Currency(id: "CNY", symbol: "¥", nameKey: "currency.cny"),
        Currency(id: "USD", symbol: "$", nameKey: "currency.usd"),
        Currency(id: "GBP", symbol: "£", nameKey: "currency.gbp"),
        Currency(id: "EUR", symbol: "€", nameKey: "currency.eur"),
        Currency(id: "JPY", symbol: "¥", nameKey: "currency.jpy"),
        Currency(id: "KRW", symbol: "₩", nameKey: "currency.krw")
    ]
    
    var currentCurrency: Currency {
        currencies.first(where: { $0.id == currencyCode }) ?? currencies[0]
    }
    
    var currentCategory: CategoryModel {
        categoryManager.getCategory(by: selectedCategoryID)
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // 1. 顶部 Header (分类选择)
                VStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text(String(localized: "record.title"))
                            .fontWeight(.medium)
                            .fontDesign(.monospaced)
                        Text(String(localized: "YourSpend"))
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                    }
                    .font(.system(size: 20))
                    .padding(.bottom, 15)
                    
                    // 分类选择按钮
                    Button(action: { showCategorySheet = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: currentCategory.icon)
                                .font(.system(size: 15, weight: .semibold))
                            Text(currentCategory.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                
                // 2. 金额显示区
                VStack(spacing: 10) {
                    HStack(alignment: .center, spacing: 10) {
                        Button(action: { showCurrencySheet = true }) {
                            HStack(spacing: 8) {
                                Text(currentCurrency.symbol)
                                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        .layoutPriority(1)
                        
                        Text(inputAmount)
                            .font(.system(size: 50, weight: .bold, design: .monospaced))
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                            .frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    
                    HStack(spacing: 20) {
                        Button(action: { showDatePicker = true }) {
                            Label(formatDateButton(selectedDate), systemImage: "calendar")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isDateToday(selectedDate) ? .secondary : .primary)
                        
                        Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1, height: 16)
                        
                        Button(action: { showNoteInput = true }) {
                            Label(note.isEmpty ? String(localized: "record.add_note") : note, systemImage: note.isEmpty ? "pencil" : "pencil.circle.fill")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(note.isEmpty ? .secondary : .primary)
                    }
                }
                .padding(.top, 10)
                
                // 3. 底部操作区
                VStack(spacing: 20) {
                    Divider()
                        .padding(.horizontal, 30)
                        .opacity(0.3)
                        .padding(.top, 10)
                        .padding(.bottom, -5)
                    
                    KeypadView(input: $inputAmount)
                        .padding(.horizontal, 30)
                    
                    PrimaryButton(
                        title: String(localized: "record"),
                        icon: "highlighter",
                        isEnabled: Double(inputAmount) ?? 0 > 0
                    ) {
                        saveTransaction()
                    }
                    .padding(.horizontal, 45)
                }
            }
            if showSuccessToast {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 45, weight: .semibold))
                        .foregroundStyle(.primary)
                                
                    Text(String(localized: "common.saved"))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .onChange(of: defaultCurrencyCode) { _, newValue in
            currencyCode = newValue
        }
        .sheet(isPresented: $showCurrencySheet) {
            VStack(spacing: 0) {
                Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 36, height: 5).padding(.top, 10).padding(.bottom, 20)
                Text(String(localized: "currency.select")).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary).padding(.bottom, 10)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(currencies) { currency in
                            Button {
                                currencyCode = currency.id
                                showCurrencySheet = false
                            } label: {
                                HStack(spacing: 8) {
                                    Text(currency.symbol).font(.headline.monospaced()).foregroundStyle(.secondary).frame(width: 30, alignment: .trailing)
                                        .frame(width: 30, alignment: .trailing)
                                    Text(currency.localizedName).font(.headline).foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                                .overlay(alignment: .trailing) {
                                    if currencyCode == currency.id {
                                        Image(systemName: "checkmark")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .padding(.trailing, 35)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.horizontal, 40)
                        }
                    }.padding(.bottom, 20)
                }
            }.presentationDragIndicator(.hidden).presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCategorySheet) {
            VStack(spacing: 0) {
                Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 36, height: 5).padding(.top, 10).padding(.bottom, 20)
                Text(String(localized: "category.select")).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary).padding(.bottom, 10)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(categoryManager.categories) { cat in
                            Button { selectedCategoryID = cat.id; showCategorySheet = false } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: cat.icon).font(.headline)
                                    Text(cat.name).font(.headline)
                                }
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                                .overlay(alignment: .trailing) {
                                    if selectedCategoryID == cat.id {
                                        Image(systemName: "checkmark")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .padding(.trailing, 35)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.horizontal, 20)
                        }
                        Button { showCategorySheet = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { tabSelection = 2; settingsPath.append(SettingsRoute.categories(autoOpenAdd: true)) } } label: {
                            HStack(spacing: 12) { Image(systemName: "plus.circle.fill").font(.headline); Text(String(localized: "category.create_custom")).font(.headline) }.foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 16).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }.padding(.bottom, 20)
                }
            }.presentationDragIndicator(.hidden).presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker(String(localized: "record.select_date"), selection: $selectedDate, in: ...Date(), displayedComponents: .date).datePickerStyle(.graphical).padding()
                PrimaryButton(title: String(localized: "common.done")) { showDatePicker = false }.padding()
            }.presentationDetents([.medium])
        }
        .alert(String(localized: "record.add_note"), isPresented: $showNoteInput) {
            TextField(String(localized: "record.note_input_placeholder"), text: $note)
            Button(String(localized: "common.done"), role: .cancel) {}
        }
    }
    
    // --- Logic ---
    private func saveTransaction() {
        guard let amount = Double(inputAmount), amount > 0 else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let newTransaction = Transaction(timestamp: selectedDate, amount: amount, categoryID: selectedCategoryID, note: note, currency: currencyCode)
        modelContext.insert(newTransaction)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { showSuccessToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.easeOut(duration: 0.2)) { showSuccessToast = false } }
        
        inputAmount = "0"
        note = ""
        selectedDate = Date()
    }
    
    func formatDateButton(_ date: Date) -> String {
        Calendar.current.isDateInToday(date) ? String(localized: "common.today") : DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
    }
    
    func isDateToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct KeypadView: View {
    @Binding var input: String
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "delete"]
    var body: some View {
        LazyVGrid(columns: columns, spacing: 25) {
            ForEach(keys, id: \.self) { key in
                Button(action: { handleTap(key) }) {
                    Circle().fill(Color(UIColor.secondarySystemFill)).frame(height: 72).overlay(
                        Group {
                            if key == "delete" { Image(systemName: "delete.left.fill").font(.title2).foregroundStyle(.primary) }
                            else { Text(key).font(.system(size: 30, weight: .regular, design: .monospaced)).foregroundStyle(.primary) }
                        }
                    )
                }.buttonStyle(NativeKeypadButtonStyle())
            }
        }
    }
    func handleTap(_ key: String) {
        let generator = UIImpactFeedbackGenerator(style: .light); generator.impactOccurred()
        if key == "delete" { if input.count > 1 { input.removeLast() } else { input = "0" } }
        else { if input == "0" && key != "." { input = key } else if input.count < 9 { input += key } }
    }
}

struct NativeKeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.95 : 1.0).opacity(configuration.isPressed ? 0.8 : 1.0).animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String; let icon: String?; let isEnabled: Bool; let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    init(title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) { self.title = title; self.icon = icon; self.isEnabled = isEnabled; self.action = action }
    var body: some View {
        let bgColor: Color = { if !isEnabled { return colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3) } else { return colorScheme == .dark ? Color.white : Color.black } }()
        let textColor: Color = colorScheme == .dark ? .black : .white
        Button(action: { guard isEnabled else { return }; action() }) {
            HStack(spacing: 8) { if let icon { Image(systemName: icon).font(.system(size: 15, weight: .semibold)) }; Text(title).font(.headline.weight(.semibold)) }
            .foregroundColor(textColor).frame(maxWidth: .infinity, minHeight: 50).background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(bgColor)).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!isEnabled).animation(nil, value: isEnabled).padding(.top, 5)
    }
}

#Preview { ContentView().modelContainer(for: Transaction.self, inMemory: true) }
