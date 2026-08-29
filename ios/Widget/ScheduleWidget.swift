import WidgetKit
import SwiftUI

// MARK: - 数据模型（与 Flutter 端保持一致）
struct WidgetCourse: Codable {
    let name: String
    let teacher: String
    let classroom: String
    let weekday: Int
    let startSection: Int
    let endSection: Int
    let weeks: [Int]?
    let weekType: Int?
    let colorIndex: Int
}

struct WidgetHoliday: Codable {
    let date: String
    let type: Int
    let weekdayOverride: Int?
}

struct WidgetData: Codable {
    let courses: [WidgetCourse]
    let holidays: [WidgetHoliday]?
    let currentWeek: Int
    let totalWeeks: Int
    let semesterStart: String // ISO8601
    let showWeekend: Bool
    let timeSlots: [WidgetTimeSlot]
}

struct WidgetTimeSlot: Codable {
    let section: Int
    let startTime: String
    let endTime: String
}

// MARK: - 课程颜色（与 Flutter 端 kCourseGradients 对应）
let widgetColors: [Color] = [
    Color(red: 0.29, green: 0.56, blue: 0.95),  // 蓝
    Color(red: 0.95, green: 0.61, blue: 0.29),  // 橙
    Color(red: 0.35, green: 0.72, blue: 0.48),  // 绿
    Color(red: 0.85, green: 0.40, blue: 0.54),  // 粉
    Color(red: 0.58, green: 0.45, blue: 0.82),  // 紫
    Color(red: 0.90, green: 0.75, blue: 0.30),  // 黄
    Color(red: 0.30, green: 0.75, blue: 0.75),  // 青
    Color(red: 0.80, green: 0.50, blue: 0.30),  // 棕
]

// MARK: - 数据提供者
struct ScheduleProvider: TimelineProvider {
    let appGroupID = "group.com.example.classSchedule"

    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), courses: [], currentWeek: 1, timeSlots: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> ()) {
        let entry = loadData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> ()) {
        let entry = loadData()
        // 每小时刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadData() -> ScheduleEntry {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "widget_data"),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return ScheduleEntry(date: Date(), courses: [], currentWeek: 1, timeSlots: [])
        }

        // 计算今天是周几，并应用假期/调休
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // 1=周日, 2=周一...
        let weekdayIndex = weekday == 1 ? 7 : weekday - 1 // 转成 1=周一 ... 7=周日
        let todayStart = calendar.startOfDay(for: today)

        var effectiveWeekday = weekdayIndex
        if let holidays = widgetData.holidays {
            for holiday in holidays {
                guard let date = ISO8601DateFormatter().date(from: holiday.date) else {
                    continue
                }
                if calendar.isDate(calendar.startOfDay(for: date), inSameDayAs: todayStart) {
                    if holiday.type == 0 {
                        return ScheduleEntry(date: today, courses: [], currentWeek: widgetData.currentWeek, timeSlots: widgetData.timeSlots)
                    }
                    if holiday.type == 1, let override = holiday.weekdayOverride {
                        effectiveWeekday = override
                    }
                }
            }
        }

        // 筛选今天的课程
        let todayCourses = widgetData.courses.filter {
            guard $0.weekday == effectiveWeekday else { return false }
            guard $0.weeks?.contains(widgetData.currentWeek) ?? true else { return false }
            switch $0.weekType ?? 0 {
            case 1:
                return widgetData.currentWeek % 2 == 1
            case 2:
                return widgetData.currentWeek % 2 == 0
            default:
                return true
            }
        }

        return ScheduleEntry(
            date: Date(),
            courses: todayCourses,
            currentWeek: widgetData.currentWeek,
            timeSlots: widgetData.timeSlots
        )
    }
}

// MARK: - Timeline Entry
struct ScheduleEntry: TimelineEntry {
    let date: Date
    let courses: [WidgetCourse]
    let currentWeek: Int
    let timeSlots: [WidgetTimeSlot]
}

// MARK: - Widget 视图
struct ScheduleWidgetEntryView: View {
    var entry: ScheduleProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - 2x2 小尺寸：显示下一节课
struct SmallWidgetView: View {
    let entry: ScheduleEntry

    var nextCourse: WidgetCourse? {
        let calendar = Calendar.current
        let now = calendar.component(.hour, from: entry.date) * 60 +
                  calendar.component(.minute, from: entry.date)

        for course in entry.courses.sorted(by: { $0.startSection < $1.startSection }) {
            if let slot = entry.timeSlots.first(where: { $0.section == course.startSection }) {
                let parts = slot.startTime.split(separator: ":")
                if parts.count == 2,
                   let h = Int(parts[0]), let m = Int(parts[1]) {
                    let courseTime = h * 60 + m
                    if courseTime > now {
                        return course
                    }
                }
            }
        }
        return nil
    }

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.14),
                    Color(red: 0.18, green: 0.18, blue: 0.22)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 6) {
                // 标题
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("第\(entry.currentWeek)周")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer(minLength: 0)

                if let course = nextCourse {
                    // 下一节课
                    let color = widgetColors[course.colorIndex % widgetColors.count]
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.9))
                        .frame(height: 52)
                        .overlay(
                            VStack(alignment: .leading, spacing: 2) {
                                Text(course.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                HStack(spacing: 3) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 9))
                                    Text(course.classroom)
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(8),
                            alignment: .leading
                        )
                } else if entry.courses.isEmpty {
                    // 今天没课
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green.opacity(0.8))
                        Text("今日无课")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // 今天课上完了
                    VStack(spacing: 4) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.yellow.opacity(0.8))
                        Text("今日课程已结束")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - 4x2 中尺寸：显示今日课程列表
struct MediumWidgetView: View {
    let entry: ScheduleEntry

    var sortedCourses: [WidgetCourse] {
        entry.courses.sorted { $0.startSection < $1.startSection }
    }

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.14),
                    Color(red: 0.18, green: 0.18, blue: 0.22)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                // 标题栏
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Text("第\(entry.currentWeek)周 · 今日课程")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Text("\(entry.courses.count)门课")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                if sortedCourses.isEmpty {
                    // 无课状态
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green.opacity(0.8))
                            Text("今日无课，好好休息")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    // 课程列表（最多显示4门）
                    ForEach(Array(sortedCourses.prefix(4).enumerated()), id: \.element.name) { index, course in
                        let color = widgetColors[course.colorIndex % widgetColors.count]
                        let time = entry.timeSlots.first(where: { $0.section == course.startSection })?.startTime ?? ""

                        HStack(spacing: 10) {
                            // 时间
                            VStack(spacing: 2) {
                                Text(time)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("第\(course.startSection)节")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .frame(width: 42, alignment: .leading)

                            // 课程卡片
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color.opacity(0.85))
                                .frame(height: 36)
                                .overlay(
                                    HStack(spacing: 6) {
                                        Text(course.name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Spacer(minLength: 0)
                                        if !course.classroom.isEmpty {
                                            Image(systemName: "mappin.and.ellipse")
                                                .font(.system(size: 9))
                                                .foregroundColor(.white.opacity(0.8))
                                            Text(course.classroom)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.85))
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.horizontal, 8),
                                    alignment: .leading
                                )
                        }
                    }

                    if sortedCourses.count > 4 {
                        Text("还有 \(sortedCourses.count - 4) 门课...")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(14)
        }
    }
}
