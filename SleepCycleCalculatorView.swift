import SwiftUI
import Foundation

struct SleepCycleCalculatorView: View {
    @State private var currentTime = Date()
    @State private var selectedBedtime = Date()
    @State private var wakeUpTimes: [Date] = []
    @State private var showingBedtimeCalculator = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let sleepCycleDuration: TimeInterval = 90 * 60 // 90 minutes in seconds
    private let fallAsleepTime: TimeInterval = 15 * 60 // 15 minutes to fall asleep
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Current Time Display
                    currentTimeSection
                    
                    Divider()
                    
                    // Sleep Calculator Options
                    calculatorOptionsSection
                    
                    if !wakeUpTimes.isEmpty {
                        Divider()
                        wakeUpTimesSection
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep Calculator")
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }
    
    private var currentTimeSection: some View {
        VStack(spacing: 10) {
            Text("Current Time")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(currentTime, style: .time)
                .font(.system(size: 48, weight: .light, design: .rounded))
                .foregroundColor(.primary)
            
            Text(currentTime, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var calculatorOptionsSection: some View {
        VStack(spacing: 20) {
            Text("Sleep Calculator")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 15) {
                // Calculate when to wake up if sleeping now
                Button(action: calculateWakeUpFromNow) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                        Text("If I sleep now, when should I wake up?")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                
                // Calculate when to sleep for specific wake up time
                Button(action: { showingBedtimeCalculator = true }) {
                    HStack {
                        Image(systemName: "alarm.fill")
                        Text("When should I sleep to wake up at a specific time?")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(10)
                }
            }
        }
        .sheet(isPresented: $showingBedtimeCalculator) {
            BedtimeCalculatorSheet(onCalculate: calculateBedtimes)
        }
    }
    
    private var wakeUpTimesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recommended Wake-up Times")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Based on 90-minute sleep cycles + 15 minutes to fall asleep")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(Array(wakeUpTimes.enumerated()), id: \.offset) { index, time in
                    WakeUpTimeCard(
                        time: time,
                        cycleCount: index + 1,
                        hoursOfSleep: Double(index + 1) * 1.5
                    )
                }
            }
        }
    }
    
    private func calculateWakeUpFromNow() {
        let bedtime = Date().addingTimeInterval(fallAsleepTime)
        wakeUpTimes = calculateOptimalWakeUpTimes(from: bedtime)
    }
    
    private func calculateBedtimes(for wakeUpTime: Date) {
        // Calculate bedtimes for different cycle counts (3-6 cycles)
        var bedtimes: [Date] = []
        for cycles in 3...6 {
            let totalSleepTime = Double(cycles) * sleepCycleDuration
            let bedtime = wakeUpTime.addingTimeInterval(-(totalSleepTime + fallAsleepTime))
            bedtimes.append(bedtime)
        }
        wakeUpTimes = bedtimes.reversed() // Show latest bedtime first
    }
    
    private func calculateOptimalWakeUpTimes(from bedtime: Date) -> [Date] {
        var times: [Date] = []
        
        // Calculate wake-up times for 3-6 sleep cycles
        for cycles in 3...6 {
            let wakeUpTime = bedtime.addingTimeInterval(Double(cycles) * sleepCycleDuration)
            times.append(wakeUpTime)
        }
        
        return times
    }
}

struct WakeUpTimeCard: View {
    let time: Date
    let cycleCount: Int
    let hoursOfSleep: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text(time, style: .time)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("\(cycleCount) cycles")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(hoursOfSleep, specifier: "%.1f") hours")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BedtimeCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWakeUpTime = Date()
    let onCalculate: (Date) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("When do you want to wake up?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                DatePicker(
                    "Wake-up time",
                    selection: $selectedWakeUpTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Button("Calculate Bedtimes") {
                    onCalculate(selectedWakeUpTime)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Set Wake-up Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview
struct SleepCycleCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        SleepCycleCalculatorView()
    }
}