import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WidgetKit
import UIKit

enum SettingsRoute: Hashable {
    case about
    case preferences
    case categories(autoOpenAdd: Bool)
}

struct CSVDocument: Transferable {
    var content: String
    var fileName: String
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { document in
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(document.fileName)
            try document.content.write(to: fileURL, atomically: true, encoding: .utf8)
            return SentTransferredFile(fileURL)
        }
    }
}

struct SettingsView: View {
    @Binding var path: NavigationPath
    @AppStorage("isCloudSyncEnabled") private var isCloudSyncEnabled: Bool = true
    @Query(sort: \Transaction.timestamp, order: .reverse) private var transactions: [Transaction]

    private var exportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "YourSpend-\(formatter.string(from: Date())).csv"
    }

    private func generateCSV() -> String {
        var csvString = "Date,Category,Amount,Note,Currency\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for transaction in transactions {
            let date = dateFormatter.string(from: transaction.timestamp).replacingOccurrences(of: ",", with: " ")
            let category = transaction.categoryModel.name
            let amount = String(format: "%.2f", transaction.amount)
            let note = transaction.note.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ")
            let currency = transaction.currency
            csvString.append("\(date),\(category),\(amount),\(note),\(currency)\n")
        }
        return csvString
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    
                    Text(String(localized: "tab.settings"))
                        .font(.system(size: 32, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 70)
                        .padding(.leading, 45)
                        .padding(.bottom, 40)

                    SettingsSectionCard {
                        NavigationLink(value: SettingsRoute.about) {
                            SettingsRow(icon: "info.circle", title: String(localized: "settings.about"), showChevron: true)
                        }
                        .buttonStyle(.plain)
                        SettingsDivider()
                        NavigationLink(value: SettingsRoute.preferences) {
                            SettingsRow(icon: "slider.horizontal.3", title: String(localized: "settings.preferences"), showChevron: true)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // ✅ 修改：独立的 iCloud 开关卡片（样式同步 Stats Total）
                    HStack {
                        Image(systemName: "icloud")
                            .font(.system(size: 20))
                            .frame(width: 28, height: 28)
                            .foregroundColor(.primary)
                        
                        Text(String(localized: "settings.icloud"))
                            .font(.system(size: 17))
                        
                        Spacer()
                        
                        Toggle("", isOn: $isCloudSyncEnabled)
                            .labelsHidden()
                            .tint(.primary) // 统一黑白风格
                    }
                    .padding(.horizontal, 20) // 内部间距
                    .padding(.vertical, 12)   // 内部高度
                    .background(
                        RoundedRectangle(cornerRadius: 12) // 圆角 12，与 Stats 一致
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal, 30) // 外部间距
                    .padding(.top, 10)
                    
                    // 下方功能组
                    SettingsSectionCard {
                        // Export CSV
                        ShareLink(item: CSVDocument(content: generateCSV(), fileName: exportFilename), preview: SharePreview(exportFilename, icon: Image(systemName: "tablecells"))) {
                            SettingsRow(icon: "square.and.arrow.up", title: String(localized: "settings.export_csv"), showChevron: true)
                        }
                        .buttonStyle(.plain)
                        
                        SettingsDivider()
                        
                        // Categories
                        NavigationLink(value: SettingsRoute.categories(autoOpenAdd: false)) {
                            SettingsRow(icon: "square.grid.2x2", title: String(localized: "settings.categories"), showChevron: true)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 5)
                    
                    Spacer(minLength: 80)
                }
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .about: AboutView()
                case .preferences: PreferencesView()
                case .categories(let autoOpenAdd): CategoriesSettingsView(autoOpenAdd: autoOpenAdd)
                }
            }
        }
    }
}

struct CategoriesSettingsView: View {
    var autoOpenAdd: Bool = false
    @ObservedObject var manager = CategoryManager.shared
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newIcon = "star.fill"
    
    struct IconCategory: Identifiable {
        let id = UUID()
        let titleKey: String
        let icons: [String]
    }

    let iconCategories: [IconCategory] = [
        IconCategory(titleKey: "icon_category.food", icons: ["fork.knife", "wineglass.fill", "cup.and.saucer.fill", "birthday.cake.fill", "takeoutbag.and.cup.and.straw.fill", "waterbottle.fill", "mug.fill", "carrot.fill"]),
        IconCategory(titleKey: "icon_category.shopping", icons: ["cart.fill", "bag.fill", "basket.fill", "creditcard.fill", "gift.fill", "tshirt.fill", "shoe.fill", "eyeglasses", "handbag.fill", "watch.analog"]),
        IconCategory(titleKey: "icon_category.transport", icons: ["car.fill", "bus.fill", "tram.fill", "airplane", "bicycle", "fuelpump.fill", "parkingsign.circle.fill", "map.fill", "suitcase.fill", "sailboat.fill"]),
        IconCategory(titleKey: "icon_category.home", icons: ["house.fill", "bed.double.fill", "chair.lounge.fill", "lightbulb.fill", "drop.fill", "wifi", "bolt.fill", "phone.fill", "tv.fill", "washer.fill"]),
        IconCategory(titleKey: "icon_category.entertainment", icons: ["gamecontroller.fill", "theatermasks.fill", "film.fill", "headphones", "guitars.fill", "ticket.fill", "music.note", "camera.fill", "photo.fill", "paintbrush.fill", "dice.fill"]),
        IconCategory(titleKey: "icon_category.health", icons: ["cross.case.fill", "pills.fill", "heart.text.square.fill", "brain.head.profile", "figure.walk", "figure.run", "dumbbell.fill", "sportscourt.fill"]),
        IconCategory(titleKey: "icon_category.education", icons: ["book.fill", "graduationcap.fill", "briefcase.fill", "paperclip", "externaldrive.fill", "printer.fill", "folder.fill", "laptopcomputer"]),
        IconCategory(titleKey: "icon_category.nature", icons: ["pawprint.fill", "leaf.fill", "flame.fill", "sun.max.fill", "moon.fill", "cloud.rain.fill", "fish.fill", "bird.fill"]),
        IconCategory(titleKey: "icon_category.tools", icons: ["scissors", "hammer.fill", "wrench.and.screwdriver.fill", "key.fill", "lock.fill", "shippingbox.fill", "trash.fill"])
    ]

    var body: some View {
        List {
            ForEach(manager.categories) { cat in
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.primary.opacity(0.05)).frame(width: 42, height: 42)
                        Image(systemName: cat.icon).font(.system(size: 20, weight: .semibold)).foregroundColor(.primary)
                    }
                    Text(cat.name).font(.body.weight(.medium))
                    Spacer()
                    if cat.isSystem {
                        Text(String(localized: "common.system")).font(.caption2.weight(.bold)).foregroundStyle(.secondary).padding(.horizontal, 8).padding(.vertical, 4).background(Color.secondary.opacity(0.1), in: Capsule())
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in manager.deleteCategory(at: indexSet) }
        }
        .navigationTitle(String(localized: "settings.categories"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(action: { showingAddSheet = true }) { Image(systemName: "plus").foregroundStyle(.primary) }
        }
        .onAppear { if autoOpenAdd { showingAddSheet = true } }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                Form {
                    Section(String(localized: "category.name")) { TextField(String(localized: "category.name_placeholder"), text: $newName) }
                    ForEach(iconCategories) { category in
                        Section(String(localized: String.LocalizationValue(category.titleKey))) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                                ForEach(category.icons, id: \.self) { icon in
                                    Image(systemName: icon).font(.title2).frame(width: 44, height: 44).background(newIcon == icon ? Color.primary.opacity(0.1) : Color.clear).foregroundStyle(.primary).cornerRadius(12).onTapGesture { newIcon = icon }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
                .navigationTitle(String(localized: "category.new"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(String(localized: "common.cancel")) { showingAddSheet = false }.foregroundStyle(.primary) }
                    ToolbarItem(placement: .confirmationAction) { Button(String(localized: "common.save")) { if !newName.isEmpty { manager.addCategory(name: newName, icon: newIcon); newName = ""; newIcon = "star.fill"; showingAddSheet = false } }.disabled(newName.isEmpty).foregroundStyle(newName.isEmpty ? .secondary : .primary) }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

struct AboutView: View {
    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (Build \(build))"
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                SettingsSectionCard { AboutValueRow(title: String(localized: "settings.version"), value: appVersionText) }.padding(.top, 25)
                Text(String(localized: "settings.follow_me")).font(.caption).foregroundColor(.secondary).padding(.leading, 40).padding(.top, 25)
                SettingsSectionCard {
                    Button { if let url = URL(string: "https://www.xiaohongshu.com/user/profile/5b472535e8ac2b399778736f") { UIApplication.shared.open(url) } } label: { SettingsRow(icon: "link", title: String(localized: "settings.follow_rednote"), showChevron: true) }.buttonStyle(.plain)
                }
                SettingsSectionCard {
                    Button { if let url = URL(string: "mailto:help.appetizer@gmail.com") { UIApplication.shared.open(url) } } label: { SettingsRow(icon: "exclamationmark.bubble", title: String(localized: "settings.report"), showChevron: true) }.buttonStyle(.plain)
                }.padding(.top, 30).padding(.bottom, 10)
                VStack(spacing: 30) {
                    VStack(spacing: -10) { Image("Time2Go").resizable().scaledToFit().frame(width: 80, height: 80); Text(String(localized: "settings.made_in")).font(.caption).foregroundStyle(.secondary) }
                    VStack { Image("Appetizer").resizable().scaledToFit().frame(width: 50, height: 50); Text(String(localized: "settings.copyright")).font(.caption2).foregroundColor(.secondary) }
                }.frame(maxWidth: .infinity).padding(.top, 110).padding(.bottom, 50)
            }.frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle(String(localized: "settings.about"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preferences
struct PreferencesView: View {
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRaw: String = "en"
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "CNY"

    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .system }
    private var isEnglish: Bool { appLanguageRaw == "en" }
    private var isChinese: Bool { appLanguageRaw == "zh-Hans" }
    private var isChineseTraditional: Bool { appLanguageRaw == "zh-Hant" }
    private var isKorean: Bool { appLanguageRaw == "ko" }
    private var isJapanese: Bool { appLanguageRaw == "ja" }
    
    private func forceSaveLanguage(_ lang: String) {
        appLanguageRaw = lang
        UserDefaults.standard.set(lang, forKey: "appLanguage")
        UserDefaults.standard.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("").padding(.top, 1)

                Text(String(localized: "preferences.currency"))
                    .font(.subheadline.weight(.semibold)).foregroundColor(.secondary).padding(.leading, 40)
                
                SettingsSectionCard {
                    NavigationLink(destination: CurrencyPickerView(selectedCurrency: $defaultCurrencyCode)) {
                        HStack {
                            Text(String(localized: "currency.default"))
                                .font(.system(size: 17))
                            Spacer()
                            Text(defaultCurrencyCode)
                                .font(.system(size: 17))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 25)

                Text(String(localized: "preferences.language"))
                    .font(.subheadline.weight(.semibold)).foregroundColor(.secondary).padding(.leading, 40)

                SettingsSectionCard {
                    ThemeOptionRow(title: String(localized: "preferences.language_en"), isSelected: isEnglish) { forceSaveLanguage("en") }
                    SettingsDivider()
                    ThemeOptionRow(title: String(localized: "preferences.language_zh"), isSelected: isChinese) { forceSaveLanguage("zh-Hans") }
                    SettingsDivider()
                    ThemeOptionRow(title: String(localized: "preferences.language_zh_hant"), isSelected: isChineseTraditional) { forceSaveLanguage("zh-Hant") }
                    SettingsDivider()
                    ThemeOptionRow(title: String(localized: "preferences.language_ko"), isSelected: isKorean) { forceSaveLanguage("ko") }
                    SettingsDivider()
                    ThemeOptionRow(title: String(localized: "preferences.language_ja"), isSelected: isJapanese) { forceSaveLanguage("ja") }
                }
                .padding(.bottom, 25)

                Text(String(localized: "preferences.appearance"))
                    .font(.subheadline.weight(.semibold)).foregroundColor(.secondary).padding(.leading, 40)

                SettingsSectionCard {
                    ThemeOptionRow(title: String(localized: "preferences.system"), isSelected: currentTheme == .system) { appThemeRaw = AppTheme.system.rawValue }
                    SettingsDivider()
                    ThemeOptionRow(title: String(localized: "preferences.light"), isSelected: currentTheme == .light) { appThemeRaw = AppTheme.light.rawValue }
                    SettingsDivider()
                    ThemeOptionRow(title: String(localized: "preferences.dark"), isSelected: currentTheme == .dark) { appThemeRaw = AppTheme.dark.rawValue }
                }
                .padding(.bottom, 25)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.bottom, 80)
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle(String(localized: "settings.preferences"))
        .navigationBarTitleDisplayMode(.inline)
        .id(appLanguageRaw)
    }
}

// ✅ 修复：强制统一为黑白风格，去除蓝色勾选
struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    
    // 与 ContentView 中的定义保持一致
    let currencies: [Currency] = [
        Currency(id: "CNY", symbol: "¥", nameKey: "currency.cny"),
        Currency(id: "USD", symbol: "$", nameKey: "currency.usd"),
        Currency(id: "GBP", symbol: "£", nameKey: "currency.gbp"),
        Currency(id: "EUR", symbol: "€", nameKey: "currency.eur"),
        Currency(id: "JPY", symbol: "¥", nameKey: "currency.jpy"),
        Currency(id: "KRW", symbol: "₩", nameKey: "currency.krw")
    ]
    
    var body: some View {
        List {
            ForEach(currencies) { currency in
                Button {
                    selectedCurrency = currency.id
                } label: {
                    HStack(spacing: 8) {
                        Text(currency.symbol)
                            .font(.headline.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                        
                        Text(currency.localizedName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if selectedCurrency == currency.id {
                            // ✅ 确保图标使用 Primary 颜色 (黑/白)
                            Image(systemName: "checkmark")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "currency.select"))
        .tint(.primary) // ✅ 关键修复：强制列表的强调色为黑/白，覆盖系统默认蓝
    }
}

struct SettingsSectionCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        VStack(spacing: 0) { content() }
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(UIColor.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(borderColor, lineWidth: 0.4))
            .padding(.horizontal, 30)
    }
    private var borderColor: Color { colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04) }
}

struct SettingsRow: View {
    let icon: String; let title: String; var value: String? = nil; var showChevron: Bool = false
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 20)).frame(width: 28, height: 28).foregroundColor(.primary)
            Text(title).font(.system(size: 17))
            Spacer()
            if let value { Text(value).font(.system(size: 17)).foregroundColor(.secondary) }
            if showChevron { Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(Color(UIColor.tertiaryLabel)) }
        }.padding(.horizontal, 16).padding(.vertical, 12).contentShape(Rectangle())
    }
}

// ⚠️ Note: SettingsToggleRow has been removed as it's no longer used.

struct ThemeOptionRow: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 17)); Spacer()
                if isSelected { Image(systemName: "checkmark").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary) }
            }.padding(.horizontal, 16).padding(.vertical, 12).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct SettingsDivider: View {
    var body: some View { Rectangle().fill(Color(UIColor.separator).opacity(0.4)).frame(height: 0.5).padding(.leading, 60) }
}

struct AboutValueRow: View {
    let title: String; let value: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "number").font(.system(size: 20)).frame(width: 28, height: 28).foregroundColor(.primary)
            Text(title).font(.system(size: 17)); Spacer()
            Text(value).font(.system(size: 17)).foregroundColor(.secondary)
        }.padding(.horizontal, 16).padding(.vertical, 12)
    }
}

enum AppTheme: String, CaseIterable { case system, light, dark }

// MARK: - Preview
#Preview {
    SettingsView(path: .constant(NavigationPath()))
        .modelContainer(for: Transaction.self, inMemory: true)
}
