import SwiftUI
import MemoryLensCorePackage
import Charts

struct HistoryView: View {
    let history: [FfiHistoryRecord]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Memory Usage Over Time")
                .font(.headline)
                .padding([.top, .horizontal])
            
            if history.isEmpty {
                VStack {
                    Spacer()
                    Text("No history available yet.")
                        .foregroundColor(.secondary)
                    Text("Waiting for next snapshot...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(history) { record in
                        LineMark(
                            x: .value("Time", Date(timeIntervalSince1970: TimeInterval(record.timestamp))),
                            y: .value("Used Memory", Double(record.usedBytes) / (1024 * 1024 * 1024))
                        )
                        .foregroundStyle(Color.blue)
                        
                        AreaMark(
                            x: .value("Time", Date(timeIntervalSince1970: TimeInterval(record.timestamp))),
                            y: .value("Used Memory", Double(record.usedBytes) / (1024 * 1024 * 1024))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let gb = value.as(Double.self) {
                            AxisValueLabel {
                                Text("\(String(format: "%.1f", gb)) GB")
                            }
                            AxisGridLine()
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, style: .time)
                            }
                            AxisGridLine()
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// Ensure FfiHistoryRecord conforms to Identifiable
extension FfiHistoryRecord: Identifiable {
    public var id: Int64 { self.timestamp }
}
