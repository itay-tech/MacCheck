import Foundation
import PDFKit
import Testing
@testable import MacCheck

struct PDFRenderingTests {

    @Test func healthReportPDFContainsVisibleContent() throws {
        let data = try #require(HealthReportPDFBuilder.build(from: sampleReport()))
        try assertPDFContains(data, strings: ["MacCheck", "Health Report", "System Information", "Health Categories"])
    }

    @Test func inspectionReportPDFContainsVisibleContent() throws {
        let data = try #require(InspectionReportPDFBuilder.build(from: sampleReport()))
        try assertPDFContains(data, strings: ["MacCheck", "Used Mac Inspection Certificate", "B", "GOOD CONDITION", "Inspection Summary"])
    }

    private func assertPDFContains(_ data: Data, strings: [String]) throws {
        #expect(data.count > 1_000)

        let document = try #require(PDFDocument(data: data))
        #expect(document.pageCount >= 1)

        let page = try #require(document.page(at: 0))
        let bounds = page.bounds(for: .mediaBox)
        #expect(bounds.width == 612)
        #expect(bounds.height == 792)

        let extracted = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")

        for string in strings {
            #expect(extracted.contains(string))
        }
    }

    private func sampleReport() -> HealthReport {
        let breakdown = HealthScoreBreakdown(
            overallScore: 85,
            batteryScore: 90,
            storageScore: 80,
            memoryScore: 88,
            startupScore: 75,
            thermalScore: 82
        )

        let storage = StorageInfo(
            totalBytes: 500_000_000_000,
            usedBytes: 300_000_000_000,
            availableBytes: 200_000_000_000,
            snapshots: [],
            analysis: StorageAnalysis(
                weeklyGrowthBytes: 1_000_000_000,
                monthlyGrowthBytes: 4_000_000_000,
                daysUntilFull: 120,
                topGrowingCategory: .documents,
                healthScore: 80,
                status: .healthy
            )
        )

        return HealthReport(
            generatedAt: Date(),
            scoreBreakdown: breakdown,
            systemInfo: SystemInfo(
                serialNumber: "TEST123",
                modelName: "MacBook Pro",
                modelIdentifier: "Mac14,9",
                macOSVersion: "15.6",
                chipName: "Apple M2 Pro"
            ),
            battery: BatteryInfo(
                hasBattery: true,
                currentChargePercentage: 78,
                healthPercentage: 92,
                designCapacityMah: 6000,
                maxCapacityMah: 5520,
                currentCapacityMah: 4300,
                cycleCount: 245,
                isCharging: false,
                condition: .normal,
                ageEstimateMonths: 18,
                replacementPredictionMonths: nil
            ),
            storage: storage,
            memory: MemoryInfo(
                totalMemoryBytes: 16_000_000_000,
                usedMemoryBytes: 10_000_000_000,
                freeMemoryBytes: 6_000_000_000,
                cachedFilesBytes: 2_000_000_000,
                swapUsedBytes: 500_000_000,
                systemMemoryPressure: .normal,
                status: .healthy
            ),
            thermal: ThermalInfo(status: .nominal, explanation: "Thermal state is nominal."),
            startupApps: [],
            isStartupDataLimited: false,
            insights: [
                HealthInsight(
                    id: UUID(),
                    title: "Storage is healthy",
                    description: "Plenty of free space available.",
                    severity: .info
                )
            ],
            recommendations: [
                Recommendation(
                    id: UUID(),
                    title: "Review startup apps",
                    description: "Disable unused login items.",
                    priority: .medium,
                    category: .startup
                )
            ]
        )
    }
}
