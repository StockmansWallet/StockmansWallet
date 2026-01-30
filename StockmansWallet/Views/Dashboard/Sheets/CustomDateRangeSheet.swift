//
//  CustomDateRangeSheet.swift
//  StockmansWallet
//
//  HIG-compliant sheet for selecting custom date range with graphical date pickers
//

import SwiftUI

struct CustomDateRangeSheet: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var timeRange: TimeRange
    @Environment(\.dismiss) private var dismiss
    
    // Debug: Local state for date pickers, initialized with existing values or defaults
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    
    init(startDate: Binding<Date?>, endDate: Binding<Date?>, timeRange: Binding<TimeRange>) {
        self._startDate = startDate
        self._endDate = endDate
        self._timeRange = timeRange
        
        // Debug: Initialize with existing dates or reasonable defaults
        let calendar = Calendar.current
        let now = Date()
        let defaultStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        _tempStartDate = State(initialValue: startDate.wrappedValue ?? defaultStart)
        _tempEndDate = State(initialValue: endDate.wrappedValue ?? now)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $tempStartDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                } header: {
                    Text("From")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Section {
                    DatePicker(
                        "End Date",
                        selection: $tempEndDate,
                        in: tempStartDate...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                } header: {
                    Text("To")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Section {
                    // Debug: Show date range summary
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(Theme.accentColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Range")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            Text(dateRangeSummary)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.secondaryText)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        HapticManager.tap()
                        // Debug: Apply selected dates and set time range to custom
                        startDate = tempStartDate
                        endDate = tempEndDate
                        timeRange = .custom
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentColor)
                    .fontWeight(.semibold)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // Debug: Format date range as readable string
    private var dateRangeSummary: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let days = Calendar.current.dateComponents([.day], from: tempStartDate, to: tempEndDate).day ?? 0
        
        return "\(formatter.string(from: tempStartDate)) - \(formatter.string(from: tempEndDate)) (\(days + 1) days)"
    }
}

#Preview {
    CustomDateRangeSheet(
        startDate: .constant(Date().addingTimeInterval(-30*24*60*60)),
        endDate: .constant(Date()),
        timeRange: .constant(.custom)
    )
}

