import SwiftUI

struct CalendarRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @State private var displayedMonth: Date = Date()
    @State private var isSelectingEndDate = false
    
    private let calendar = Calendar.current
    
    // 获取当前展示月份的日期数组
    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        
        var dates: [Date] = []
        var current = monthInterval.start
        while current < monthInterval.end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. 头部：月份切换 (完全参照 MinimalCalendar)
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthTitle(displayedMonth))
                    .font(.headline)
                    // 防止文字变化时的抖动动画
                    .animation(nil, value: displayedMonth)
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            // 2. 星期标题
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day.prefix(1).uppercased())
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 3. 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                
                // 计算首日偏移量 (根据 monthInterval.start)
                let monthStart = calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
                let firstWeekday = calendar.component(.weekday, from: monthStart)
                // 计算 offset: 假设日历首日是周日(1)。如果是周一(2)，需要相应调整逻辑。
                // 通用公式：(weekday - firstWeekday + 7) % 7
                let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
                
                // 空白占位符
                ForEach(0..<offset, id: \.self) { _ in
                    Color.clear.frame(height: 32)
                }
                
                // 真实日期
                ForEach(days, id: \.self) { day in
                    dayView(day)
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            // 4. 底部显示选中的范围
            VStack(spacing: 8) {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "stats.range.start"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatDateFull(startDate))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(localized: "stats.range.end"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatDateFull(endDate))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding(20)
        // 初始化显示的月份
        .onAppear {
            updateDisplayedMonth(to: startDate)
        }
        // 支持左右滑动切换月份
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        changeMonth(by: 1)
                    } else if value.translation.width > 50 {
                        changeMonth(by: -1)
                    }
                }
        )
    }
    
    // MARK: - Subviews & Logic
    
    private func dayView(_ day: Date) -> some View {
        let state = getDayState(for: day)
        let isToday = calendar.isDateInToday(day)
        
        let textColor: Color = {
            switch state {
            case .start, .end: return Color(UIColor.systemBackground)
            case .range: return .primary
            case .none: return isToday ? .primary : .primary
            }
        }()
        
        let backgroundColor: Color = {
            switch state {
            case .start, .end: return .primary
            case .range: return .primary.opacity(0.1)
            case .none: return .clear
            }
        }()
        
        return ZStack {
            // 背景圆圈
            Circle()
                .fill(backgroundColor)
            
            // 日期数字
            Text("\(calendar.component(.day, from: day))")
                .font(.system(size: 16, weight: (state == .start || state == .end) ? .bold : .medium, design: .rounded))
                .foregroundColor(textColor)
            
            // 今日指示点 (未选中状态下)
            if isToday && state == .none {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 4, height: 4)
                    .offset(y: 12)
            }
        }
        .frame(height: 32)
        .contentShape(Circle())
        .onTapGesture {
            // 触觉反馈
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            
            handleDateSelection(day)
        }
    }
    
    // 判断日期状态
    enum DayState { case none, start, end, range }
    
    private func getDayState(for date: Date) -> DayState {
        if calendar.isDate(date, inSameDayAs: startDate) { return .start }
        if calendar.isDate(date, inSameDayAs: endDate) { return .end }
        // 比较时忽略时间，只比较日期，避免边界问题
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        let targetDay = calendar.startOfDay(for: date)
        
        if targetDay > startDay && targetDay < endDay { return .range }
        return .none
    }
    
    // 选择逻辑
    private func handleDateSelection(_ date: Date) {
        let selectedDayStart = calendar.startOfDay(for: date)
        let selectedDayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
        
        if !isSelectingEndDate {
            // 第一次点击：设为起点，终点暂设为同一天
            withAnimation(.snappy(duration: 0.2)) {
                startDate = selectedDayStart
                endDate = selectedDayEnd
            }
            isSelectingEndDate = true
        } else {
            // 第二次点击
            if selectedDayStart < startDate {
                // 如果点在起点之前，重置起点
                withAnimation(.snappy(duration: 0.2)) {
                    startDate = selectedDayStart
                    endDate = selectedDayEnd
                }
                // 保持选择终点状态
            } else {
                // 点在起点之后，设为终点
                withAnimation(.snappy(duration: 0.2)) {
                    endDate = selectedDayEnd
                }
                isSelectingEndDate = false
            }
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = newMonth
            }
        }
    }
    
    private func updateDisplayedMonth(to date: Date) {
        let comps = calendar.dateComponents([.year, .month], from: date)
        displayedMonth = calendar.date(from: comps) ?? date
    }
    
    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
