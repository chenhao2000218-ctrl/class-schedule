//
//  ScheduleWidget.swift
//  课程表 iOS 桌面小组件
//  遵循 WidgetKit 规范，支持小/中/大三种尺寸
//

import WidgetKit
import SwiftUI

// MARK: - 数据模型

struct CourseItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let teacher: String
    let classroom: String
    let startTime: String
    let endTime: String
    let color: Int

    enum CodingKeys: String, CodingKey {
        case name, teacher, classroom, startTime, endTime, color
    }
}

struct WidgetData: Codable {
    let date: String
    let week: Int
    let courses: [CourseItem]
}

// MARK: - 颜色映射（与 Flutter 端 kCourseColors 对应）

let widgetColors: [Color] = [
    Color(red: 0.455, green: 0.725, blue: 1.0),
    Color(red: 0.635, green: 0.608, blue: 0.996),
    Color(red: 0.333, green: 0.937, blue: 0.769),
    Color(red: 0.992, green: 0.796, blue: 0.431),
    Color(red: 1.0, green: 0.463, blue: 0.459),
    Color(red: 0.506, green: 0.925, blue: 0.925),
    Color(red: 0.980, green: 0.694, blue: 0.627),
    Color(red: 0.455, green: 0.725, blue: 1.0),
    Color(red: 0.875, green: 0.902, blue: 0.914),
    Color(red: 0.722, green: 0.914, blue: 0.580),
    Color(red: 0.424, green: 0.361, blue: 0.906),
    Color(red: 0.0, green: 0.722, blue: 0.576),
]

func courseColor(_ index: Int) -> Color {
    widgetColors[index % widgetColors.count]
}

// MARK: - Provider

struct ScheduleProvider: TimelineProvider {
    /// App Group ID，需与 Xcode 中配置一致
    let appGroupID = "group.com.example.classschedule"

    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            week: 1,
            courses: [
                CourseItem(name: "高等数学", teacher: "张教授", classroom: "A101", startTime: "08:00", endTime: "09:40", color: 0),
                CourseItem(name: "大学英语", teacher: "李老师", classroom: "B203", startTime: "10:00", endTime: "11:40", color: 1),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let entry = loadCurrentEntry()
        // 每小时刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// 从 App Group 共享目录读取课程数据
    private func loadCurrentEntry() -> ScheduleEntry {
        guard let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID),
              let data = try? Data(contentsOf: containerURL.appendingPathComponent("widget_data.json")),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            // 无数据时返回空状态
            return ScheduleEntry(date: Date(), week: 0, courses: [])
        }
        return ScheduleEntry(date: Date(), week: widgetData.week, courses: widgetData.courses)
    }
}

// MARK: - Entry

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let week: Int
    let courses: [CourseItem]
}

// MARK: - Widget View

struct ScheduleWidgetEntryView: View {
    var entry: ScheduleProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// 小号：显示下一节课
struct SmallWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("第 \(entry.week) 周")
                .font(.caption2)
                .foregroundColor(.secondary)
            if let course = entry.courses.first {
                Text(course.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(course.startTime)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(courseColor(course.color))
                if !course.classroom.isEmpty {
                    Text(course.classroom)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Spacer()
                Text("今日无课")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// 中号：显示今日课程列表（最多3节）
struct MediumWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("今日课程")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("第 \(entry.week) 周")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if entry.courses.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("今天没有课，好好休息")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.courses.prefix(3)) { course in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(courseColor(course.color))
                            .frame(width: 4)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text("\(course.startTime) · \(course.classroom)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}

// 大号：显示完整今日课程列表
struct LargeWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("今日课程")
                    .font(.headline)
                Spacer()
                Text("第 \(entry.week) 周")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Divider()
            if entry.courses.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("今天没有课")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.courses) { course in
                    HStack(spacing: 12) {
                        VStack {
                            Text(course.startTime)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(course.endTime)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 50, alignment: .leading)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(courseColor(course.color))
                            .frame(width: 4, height: 40)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(course.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if !course.teacher.isEmpty {
                                Text(course.teacher)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if !course.classroom.isEmpty {
                                Text(course.classroom)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
    }
}

// MARK: - Widget 定义

@main
struct ScheduleWidget: Widget {
    let kind: String = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleProvider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("课程表")
        .description("查看今日课程安排")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
