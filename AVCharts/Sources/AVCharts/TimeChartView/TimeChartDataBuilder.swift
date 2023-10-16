//
//  TimeChartDataBuilder.swift
//  Sample
//
//  Created by Александр Волков on 14.10.2023.
//

import Foundation

extension TimeChartView {
    public static var builder: TimeChartDataBuilder {
        return TimeChartDataBuilder()
    }
}

public final class TimeChartDataBuilder {
    public typealias ChartData = TimeChartViewModel.ChartData
    
    public enum Gap {
        case mounth(period: Int)
        case weekOfMounth(period: Int)
        case minute(period: Int)
        case day(period: Int)
        case hour(period: Int)
    }
    
    public func automaticBuild(data: [ChartData], text: String, xAxisFormatter: ((TimeChartViewModel.TimeData) -> String?)? = nil, xAxisPeriod: Int = 3) -> TimeChartViewModel {
        guard let startPosition = data.first,
              let endPosition = data.last else {
            return TimeChartViewModel(chartData: [], gap: TimeChartViewModel.Gap(measure: .day, period: 1, xAxisPeriod: xAxisPeriod), text: text, max: 0, xAxisFormatter: nil)
        }
        
        let calendar = Calendar.current
        let duration = calendar.dateComponents([.year, .month, .weekOfMonth, .day, .hour, .minute], from: startPosition.date, to: endPosition.date)
        let gap: Gap = {
            if let year = duration.year,
               year > 0 {
                // year
                return .mounth(period: 1)
            }
            if let month = duration.month,
               month > 0 {
                if month > 1 {
                    return .mounth(period: 1)
                }
                if month == 1 {
                    if let weekOfMonth = duration.weekOfMonth,
                       weekOfMonth > 1 {
                        return .weekOfMounth(period: 1)
                    }
                    
                    return .day(period: 1)
                }
            }
            if let weekOfMonth = duration.weekOfMonth,
               weekOfMonth > 0 {
                if weekOfMonth == 4 {
                    return .day(period: 1)
                }
                if weekOfMonth > 2 && weekOfMonth < 4 {
                    return .day(period: 2)
                }
                if weekOfMonth <= 2 {
                    return .day(period: 1)
                }
                return .weekOfMounth(period: 1)
            }
            if let day = duration.day,
               day > 0 {
                return .day(period: 1)
            }
            if let hour = duration.hour,
               hour > 0 {
                if hour > 23 && hour < 25 {
                    return .minute(period: 30)
                }
                if hour >= 6 {
                    return .hour(period: 1)
                }
                if hour < 6 && hour >= 1 {
                    if let minute = duration.minute {
                        return .minute(period: ((hour * 3600 + minute * 60) / 24) / 60)
                    }
                    return .minute(period: 30)
                }
                if hour <= 1 {
                    return .minute(period: 15)
                }
                return .day(period: 1)
            }
            if let minute = duration.minute {
                if minute > 60 {
                    return .minute(period: 15)
                }
                if minute <= 60 && minute >= 30 {
                    return .minute(period: 5)
                }
                if minute < 30 {
                    return .minute(period: 1)
                }
                return .minute(period: 5)
            }
            
            return .day(period: 1)
        }()
        
        return build(data: data, gap: gap, text: text, xAxisFormatter: xAxisFormatter, xAxisPeriod: xAxisPeriod)
    }
    
    public func build(data: [ChartData], gap: Gap, text: String, xAxisFormatter: ((TimeChartViewModel.TimeData) -> String?)? = nil, xAxisPeriod: Int = 3) -> TimeChartViewModel {
        var newArray = [ChartData]()
        var currentPeriod: (start: Date, end: Date)?

        for item in data {
            guard !newArray.isEmpty else {
                let newItem = ChartData(id: item.id, value: item.value, date: item.date.zeroSeconds()!)
                newArray.append(newItem)
                currentPeriod = chooseGap(date: item.date, gap: gap)
                continue
            }

            guard let currentPeriodUnwrapped = currentPeriod else {
                continue
            }

            if item.date > currentPeriodUnwrapped.start && item.date < currentPeriodUnwrapped.end {
                let element = newArray.removeLast()
                let newElement = ChartData(id: element.id, value: element.value + item.value, date: element.date.zeroSeconds()!)
                newArray.append(newElement)
                continue
            }

            currentPeriod = chooseGap(date: item.date, gap: gap)
            let newItem = ChartData(id: item.id, value: item.value, date: item.date.zeroSeconds()!)
            newArray.append(newItem)
        }
        
        let gap: TimeChartViewModel.Gap = {
            let measure: (Calendar.Component, Int) = {
                switch gap {
                case let .weekOfMounth(period):
                    return (.weekOfMonth, period)
                    
                case let .day(period):
                    return (.day, period)
                    
                case let .hour(period):
                    return (.hour, period)
                    
                case let .minute(period):
                    return (.minute, period)
                    
                case let .mounth(period):
                    return (.month, period)
                }
            }()
            
            return TimeChartViewModel.Gap(measure: measure.0, period: measure.1, xAxisPeriod: xAxisPeriod)
        }()
        
        return TimeChartViewModel(
            chartData: newArray,
            gap: gap,
            text: text,
            max: Int(newArray.max(by: { $0.value < $1.value })?.value ?? 100),
            xAxisFormatter: xAxisFormatter
        )
    }
    
    private func chooseGap(date: Date, gap: Gap) -> (start: Date, end: Date)? {
        switch gap {
        case .day(let period):
            return buildDayPeriod(date, period: period)
            
        case .hour(let period):
            return buildHourPeriod(date, period: period)
            
        case .minute(let period):
            return buildMinutePeriod(date, period: period)
            
        case .weekOfMounth(let period):
            return buildWeekOfPeriod(date, period: period)
        
        case .mounth(let period):
            return buildMounthOfPeriod(date, period: period)
        }
    }
    
    private func buildMounthOfPeriod(_ date: Date, period: Int) -> (start: Date, end: Date)? {
        let startHour = Calendar.current.startOfDay(for: date).dropDays()!
        
        guard let endHour = Calendar.current.date(byAdding: .month, value: 1, to: startHour) else {
            return nil
        }
        
        print(startHour, endHour.addingTimeInterval(-1))
        return (startHour, endHour.addingTimeInterval(-1))
    }
    
    private func buildWeekOfPeriod(_ date: Date, period: Int) -> (start: Date, end: Date)? {
        guard let startHour = date.zeroSeconds() else {
            return nil
        }
        let endHour = startHour.addingTimeInterval(TimeInterval(3600 * 24 * 7 * period - 1))
        return (startHour, endHour)
    }
    
    private func buildMinutePeriod(_ date: Date, period: Int) -> (start: Date, end: Date)? {
        guard let startHour = date.zeroSeconds() else {
            return nil
        }
        let endHour = startHour.addingTimeInterval(TimeInterval(60 * period))
        return (startHour, endHour)
    }

    private func buildHourPeriod(_ date: Date, period: Int) -> (start: Date, end: Date)? {
        guard let startHour = date.zeroMinutes() else {
            return nil
        }
        let endHour = startHour.addingTimeInterval(TimeInterval(3600 * period - 1))
        return (startHour, endHour)
    }

    private func buildDayPeriod(_ date: Date, period: Int) -> (start: Date, end: Date)? {
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = startDate.addingTimeInterval(TimeInterval(3600 * 24 * period - 1))

        return (startDate, endDate)
    }
}

extension Date {
    func zeroMinutes() -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        return calendar.date(from: dateComponents)
    }
    
    func zeroSeconds() -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return calendar.date(from: dateComponents)
    }
    
    func dropDays() -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: dateComponents)
    }
}
