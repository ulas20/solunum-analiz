import CoreData
import Foundation

final class CoreDataService: ObservableObject {

    static let shared = CoreDataService()

    // MARK: - Persistent Container

    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SolunumAI")
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData yüklenemedi: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var context: NSManagedObjectContext { container.viewContext }

    private init() {}

    // MARK: - Save

    func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData kayıt hatası: \(error.localizedDescription)")
        }
    }

    // MARK: - Insert Analysis

    @discardableResult
    func saveAnalysis(response: AnalysisResponse, request: AnalysisRequest) -> SavedAnalysis {
        let entity = AnalysisEntity(context: context)
        entity.id            = UUID()
        entity.date          = Date()
        entity.p1            = response.p1
        entity.p2            = response.p2
        entity.pFinal        = response.pFinal
        entity.airsPred      = Int16(response.airsPred)
        entity.airsIsim      = response.airsIsim
        entity.karar         = response.genel      // CoreData field "karar" stores genel
        entity.altKarar      = response.altKarar
        entity.oneri         = response.oneri
        entity.yas           = Int16(request.yas)
        entity.cinsiyet      = request.cinsiyetLabel
        entity.ates          = request.ates
        entity.solunumSorunu = false               // removed from new spec, kept for schema compat
        entity.sigara        = request.sigara
        saveContext()
        return entity.toSavedAnalysis()
    }

    // MARK: - Fetch All

    func fetchAll() -> [SavedAnalysis] {
        let req = AnalysisEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(req))?.map { $0.toSavedAnalysis() } ?? []
    }

    // MARK: - Delete

    func delete(id: UUID) {
        let req = AnalysisEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let obj = (try? context.fetch(req))?.first {
            context.delete(obj)
            saveContext()
        }
    }

    func deleteAll() {
        let req: NSFetchRequest<NSFetchRequestResult> = AnalysisEntity.fetchRequest()
        let batch = NSBatchDeleteRequest(fetchRequest: req)
        _ = try? context.execute(batch)
        saveContext()
    }

    // MARK: - CSV Export

    func exportCSV() -> String {
        let all = fetchAll()
        var lines = ["Tarih,P1,P2,P_Final,AIRS,Genel,Yas,Cinsiyet"]
        for a in all {
            let date = ISO8601DateFormatter().string(from: a.date)
            lines.append("\(date),\(a.p1),\(a.p2),\(a.pFinal),\(a.airsIsim),\(a.genel),\(a.yas),\(a.cinsiyet)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Stats

    var totalCount: Int { fetchAll().count }

    var lastAnalysisDate: Date? { fetchAll().first?.date }

    var streakDays: Int {
        let dates = fetchAll().map { Calendar.current.startOfDay(for: $0.date) }
        var uniqueDays = Array(Set(dates)).sorted(by: >)
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 1
        let today = Calendar.current.startOfDay(for: Date())
        guard uniqueDays[0] == today || uniqueDays[0] == Calendar.current.date(byAdding: .day, value: -1, to: today)! else {
            return 1
        }
        for i in 1..<uniqueDays.count {
            let diff = Calendar.current.dateComponents([.day], from: uniqueDays[i], to: uniqueDays[i-1]).day ?? 0
            if diff == 1 { streak += 1 } else { break }
        }
        return streak
    }
}

// MARK: - AnalysisEntity → SavedAnalysis

extension AnalysisEntity {
    func toSavedAnalysis() -> SavedAnalysis {
        SavedAnalysis(
            id:       id ?? UUID(),
            date:     date ?? Date(),
            p1:       p1,
            p2:       p2,
            pFinal:   pFinal,
            airsPred: Int(airsPred),
            airsIsim: airsIsim ?? "—",
            genel:    karar    ?? "—",   // CoreData "karar" field stores genel
            altKarar: altKarar ?? "—",
            oneri:    oneri    ?? "—",
            yas:      Int(yas),
            cinsiyet: cinsiyet ?? "—",
            ates:     ates,
            sigara:   sigara
        )
    }
}
