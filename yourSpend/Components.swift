import SwiftUI

// 复用 Time2Go 的主按钮风格
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isEnabled: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        let bgColor: Color = {
            if !isEnabled {
                return colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
            }
            return colorScheme == .dark ? Color.white : Color.black
        }()
        
        let textColor: Color = {
             if !isEnabled { return .gray }
             return colorScheme == .dark ? .black : .white
        }()
        
        Button(action: { guard isEnabled else { return }; action() }) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.headline.weight(.bold))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity, minHeight: 56) // 稍微加高一点，更有质感
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(bgColor))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}
