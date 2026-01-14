import SwiftUI
import Combine
import UIKit
import WidgetKit
import SwiftData
import UniformTypeIdentifiers // ✅ 1. 必须引入这个库，用来识别文件类型

// 路由枚举
private enum SettingsRoute: Hashable {
    case about
    case preferences
}

// ✅ 2. 定义一个符合 Transferable 的 CSV 文档结构
// 这告诉系统：我要分享的是一个 .csv 文件，不是普通文本
struct CSVDocument: Transferable {
    var content: String
    var fileName: String
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { document in
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(document.fileName)
            // 写入文件
            try document.content.write(to: fileURL, atomically: true, encoding: .utf8)
            return SentTransferredFile(fileURL)
        }
    }
}

struct SettingsView: View {
    @Binding var path: NavigationPath
    
    // iCloud 开关
    @AppStorage("isCloudSyncEnabled") private var isCloudSyncEnabled: Bool = true
    
    // 读取所有交易记录
    @Query(sort: \Transaction.timestamp, order: .reverse) private var transactions: [Transaction]

    // 生成文件名
    private var exportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let dateString = formatter.string(from: Date())
        return "YourSpend-\(dateString).csv"
    }

    // 生成 CSV 文本内容
    private func generateCSV() -> String {
        var csvString = "Date,Category,Amount,Note\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for transaction in transactions {
            let date = dateFormatter.string(from: transaction.timestamp).replacingOccurrences(of: ",", with: " ")
            let category = transaction.category.rawValue
            let amount = String(format: "%.2f", transaction.amount)
            let note = transaction.note.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ")
            
            csvString.append("\(date),\(category),\(amount),\(note)\n")
        }
        return csvString
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    
                    // 1. 大标题
                    Text(String(localized: "tab.settings"))
                        .font(.system(size: 32, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 70)
                        .padding(.leading, 45)
                        .padding(.bottom, 40)

                    // 2. 常规设置
                    SettingsSectionCard {
                        NavigationLink(value: SettingsRoute.about) {
                            SettingsRow(
                                icon: "info.circle",
                                title: String(localized: "settings.about"),
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)

                        SettingsDivider()

                        NavigationLink(value: SettingsRoute.preferences) {
                            SettingsRow(
                                icon: "slider.horizontal.3",
                                title: String(localized: "settings.preferences"),
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 3. 数据管理
                    SettingsSectionCard {
                        SettingsToggleRow(
                            icon: "icloud",
                            title: String(localized: "settings.icloud"),
                            isOn: $isCloudSyncEnabled
                        )
                        
                        SettingsDivider()
                        
                        // ✅ 3. 修改 ShareLink，传入 CSVDocument 对象
                        // 这样 iOS 就会把它识别为 CSV 文件，而不是 txt
                        let document = CSVDocument(content: generateCSV(), fileName: exportFilename)
                        
                        ShareLink(
                            item: document,
                            preview: SharePreview(exportFilename, icon: Image(systemName: "tablecells"))
                        ) {
                            SettingsRow(
                                icon: "square.and.arrow.up",
                                title: String(localized: "settings.export_csv"),
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 80)
                }
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .about: AboutView()
                case .preferences: PreferencesView()
                }
            }
        }
    }
}

// MARK: - AboutView
struct AboutView: View {
    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (Build \(build))"
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                
                SettingsSectionCard {
                    AboutValueRow(
                        title: String(localized: "settings.version"),
                        value: appVersionText
                    )
                }
                .padding(.top, 25)
                
                Text(String(localized: "settings.follow_me"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 40)
                    .padding(.top, 25)
                
                SettingsSectionCard {
                    Button {
                        if let url = URL(string: "https://www.xiaohongshu.com/user/profile/5b472535e8ac2b399778736f") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        SettingsRow(
                            icon: "link",
                            title: String(localized: "settings.follow_rednote"),
                            showChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                SettingsSectionCard {
                    Button {
                        if let url = URL(string: "mailto:help.appetizer@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        SettingsRow(
                            icon: "exclamationmark.bubble",
                            title: String(localized: "settings.report"),
                            showChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 30)
                .padding(.bottom, 10)
                
                VStack(spacing: 30) {
                    VStack(spacing: -10) {
                        Image("Time2Go")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                        
                        Text(String(localized: "settings.made_in"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Image("Appetizer")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        
                        Text(String(localized: "settings.copyright"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 110)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle(String(localized: "settings.about"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - PreferencesView
struct PreferencesView: View {
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRaw: String = "en"

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

// MARK: - UI Components
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

struct SettingsToggleRow: View {
    let icon: String; let title: String; var subtitle: String? = nil; @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 20)).frame(width: 28, height: 28).foregroundColor(.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 17))
                if let subtitle { Text(subtitle).font(.footnote).foregroundColor(.secondary) }
            }
            Spacer(); Toggle("", isOn: $isOn).labelsHidden()
        }.padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct ThemeOptionRow: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 17)); Spacer()
                if isSelected { Image(systemName: "checkmark").font(.system(size: 16, weight: .semibold)).foregroundColor(.accentColor) }
            }.padding(.horizontal, 16).padding(.vertical, 12).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct SettingsDivider: View {
    var body: some View { Rectangle().fill(Color(UIColor.separator).opacity(0.4)).frame(height: 0.5).padding(.leading, 60) }
}

enum AppTheme: String, CaseIterable { case system, light, dark }

#Preview {
    SettingsView(path: .constant(NavigationPath()))
}
