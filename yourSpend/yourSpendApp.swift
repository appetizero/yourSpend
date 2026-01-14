import SwiftUI
import SwiftData
import UIKit

@main
struct yourSpendApp: App {
    // ✅ 新增：监听用户设置
    @AppStorage("appTheme") private var appThemeRaw: String = "system"
    @AppStorage("appLanguage") private var appLanguageRaw: String = "en"
    
    // 计算当前应该显示的颜色模式
    private var currentScheme: ColorScheme? {
        if appThemeRaw == "light" { return .light }
        if appThemeRaw == "dark" { return .dark }
        return nil
    }

    init() {
        // TabBar 外观设置 (保持不变)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .white
        }

        let normalColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .lightGray : .darkGray
        }
        let selectedColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : .black
        }

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        appearance.selectionIndicatorImage = UIImage.selectionPill(
            color: UIColor { trait in
                trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.20, alpha: 1.0)
                : UIColor(white: 0.92, alpha: 1.0)
            }
        )
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
        ])
        
        // 读取 CloudKit 开关
        let isCloudEnabled = UserDefaults.standard.object(forKey: "isCloudSyncEnabled") as? Bool ?? true
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: isCloudEnabled ? .automatic : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // ✅ 修复 1: 强制应用语言环境 (解决部分组件不刷新问题)
                .environment(\.locale, Locale(identifier: appLanguageRaw))
                // ✅ 修复 2: 强制应用深色/浅色模式
                .preferredColorScheme(currentScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}

// (UIImage 扩展保持不变)
extension UIImage {
    static func selectionPill(
        color: UIColor,
        size: CGSize = CGSize(width: 64, height: 36),
        cornerRadius: CGFloat = 18
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.addPath(path.cgPath)
            ctx.cgContext.fillPath()
        }
        return img.resizableImage(
            withCapInsets: UIEdgeInsets(
                top: cornerRadius, left: cornerRadius,
                bottom: cornerRadius, right: cornerRadius
            )
        )
    }
}
