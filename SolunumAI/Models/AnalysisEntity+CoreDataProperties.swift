import CoreData
import Foundation

extension AnalysisEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AnalysisEntity> {
        NSFetchRequest<AnalysisEntity>(entityName: "AnalysisEntity")
    }

    @NSManaged public var id:            UUID?
    @NSManaged public var date:          Date?
    @NSManaged public var p1:            Double
    @NSManaged public var p2:            Double
    @NSManaged public var pFinal:        Double
    @NSManaged public var airsPred:      Int16
    @NSManaged public var airsIsim:      String?
    @NSManaged public var karar:         String?
    @NSManaged public var altKarar:      String?
    @NSManaged public var oneri:         String?
    @NSManaged public var yas:           Int16
    @NSManaged public var cinsiyet:      String?
    @NSManaged public var ates:          Bool
    @NSManaged public var solunumSorunu: Bool
    @NSManaged public var sigara:        Bool
}

extension AnalysisEntity: Identifiable {}
