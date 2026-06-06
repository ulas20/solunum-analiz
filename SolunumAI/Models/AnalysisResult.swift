import Foundation

// MARK: - API Request

struct AnalysisRequest {
    var yas: Int = 30
    var cinsiyet: Int = 1          // 0 = Kadın, 1 = Erkek
    var ates: Bool = false
    var sigara: Bool = false
    var wheezeGecmis: Bool = false
    var balgam: Bool = false
    var aileAstim: Bool = false
    var tbTemas: Bool = false
    var packYears: Int = 0

    var cinsiyetLabel: String { cinsiyet == 1 ? "Erkek" : "Kadın" }

    func toMetadataJSON() -> String {
        let dict: [String: Any] = [
            "yas":           yas,
            "cinsiyet":      cinsiyet,
            "wheeze_gecmis": wheezeGecmis,
            "balgam":        balgam,
            "ates":          ates,
            "aile_astim":    aileAstim,
            "tb_temas":      tbTemas,
            "sigara":        sigara,
            "pack_years":    packYears
        ]
        let data = try? JSONSerialization.data(withJSONObject: dict)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
}

// MARK: - API Response

struct AnalysisResponse: Codable {
    let p1: Double
    let p2: Double
    let pFinal: Double
    let pFinalYuzde: Double
    let airsPred: Int
    let airsIsim: String
    let genel: String
    let altKarar: String
    let oneri: String

    enum CodingKeys: String, CodingKey {
        case p1, p2
        case pFinal       = "p_final"
        case pFinalYuzde  = "p_final_yuzde"
        case airsPred     = "airs_pred"
        case airsIsim     = "airs_isim"
        case genel
        case altKarar     = "alt_karar"
        case oneri
    }

    var riskLevel: RiskLevel {
        switch pFinal {
        case ..<0.40: return .low
        case 0.40..<0.50: return .moderate
        default: return .high
        }
    }
}

// MARK: - Risk Level

enum RiskLevel: String, CaseIterable {
    case low      = "Düşük Risk"
    case moderate = "Orta Risk"
    case high     = "Yüksek Risk"

    var color: String {
        switch self {
        case .low:      return "AppSuccess"
        case .moderate: return "AppWarning"
        case .high:     return "AppDanger"
        }
    }

    var emoji: String {
        switch self {
        case .low:      return "✅"
        case .moderate: return "⚠️"
        case .high:     return "🚨"
        }
    }
}

// MARK: - Saved Analysis (value type mirroring CoreData entity)

struct SavedAnalysis: Identifiable {
    var id: UUID
    var date: Date
    var p1: Double
    var p2: Double
    var pFinal: Double
    var airsPred: Int
    var airsIsim: String
    var genel: String
    var altKarar: String
    var oneri: String
    var yas: Int
    var cinsiyet: String   // "Erkek" | "Kadın"
    var ates: Bool
    var sigara: Bool

    var riskLevel: RiskLevel {
        switch pFinal {
        case ..<0.40: return .low
        case 0.40..<0.50: return .moderate
        default: return .high
        }
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    var formattedPFinal: String {
        String(format: "%.1f%%", pFinal * 100)
    }
}

// MARK: - Health Tips

struct HealthTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let shortDesc: String
    let detail: String

    static let all: [HealthTip] = [
        HealthTip(
            icon: "lungs",
            title: "Öksürük Nedir?",
            shortDesc: "Farklı öksürük türleri ve ne zaman doktora gitmelisiniz.",
            detail: """
            Öksürük, vücudun hava yollarını temizleme mekanizmasıdır. Kuru, balgamlı, kronik ve akut olmak üzere çeşitleri vardır.

            **Kuru Öksürük:** Genellikle viral enfeksiyonlar veya alerjiler sonucu oluşur.
            **Balgamlı Öksürük:** Solunum yollarında enfeksiyon işareti olabilir.
            **Kronik Öksürük:** 8 haftadan uzun süren öksürük; KOAH, astım veya GERD kaynaklı olabilir.

            **Doktora gidin eğer:**
            • Öksürük 3 haftadan uzun sürüyorsa
            • Kanda balgam görüyorsanız
            • Nefes almakta güçlük çekiyorsanız
            • Yüksek ateşle birlikte geliyorsa
            """
        ),
        HealthTip(
            icon: "thermometer",
            title: "COVID-19 Belirtileri",
            shortDesc: "Ateş, kuru öksürük, nefes darlığı başlıca belirtilerdir.",
            detail: """
            COVID-19, SARS-CoV-2 virüsünün neden olduğu solunum yolu hastalığıdır.

            **Yaygın Belirtiler:**
            • Ateş veya üşüme
            • Kuru öksürük
            • Nefes darlığı
            • Yorgunluk
            • Kas ve baş ağrısı
            • Tat ve koku kaybı

            **Ciddi Belirtiler (acil müdahale gerektirir):**
            • Ciddi nefes darlığı
            • Göğüs ağrısı veya baskı
            • Bilinç bulanıklığı
            • Dudakların mavileşmesi

            Belirtiler başladıktan 2-14 gün içinde ortaya çıkabilir.
            """
        ),
        HealthTip(
            icon: "wind",
            title: "Astım Hakkında",
            shortDesc: "Tetikleyiciler, belirtiler ve günlük yaşam yönetimi.",
            detail: """
            Astım, hava yollarının kronik inflamatuar hastalığıdır. Türkiye'de yaklaşık 3 milyon kişiyi etkiler.

            **Yaygın Tetikleyiciler:**
            • Polen, toz akarları, hayvan tüyü
            • Sigara dumanı ve hava kirliliği
            • Soğuk hava ve egzersiz
            • Stres ve güçlü duygular
            • Bazı ilaçlar (aspirin, beta blokerler)

            **Belirtiler:**
            • Hırıltılı solunum (wheezing)
            • Nefes darlığı
            • Göğüste sıkışma hissi
            • Özellikle gece kötüleşen öksürük

            **Yönetim:**
            Düzenli kontrolörler ve acil inhaler kullanımı, tetikleyicilerden uzak durma.
            """
        ),
        HealthTip(
            icon: "smoke",
            title: "KOAH Nedir?",
            shortDesc: "Sigara en önemli neden — belirtiler ve hastalığın seyri.",
            detail: """
            KOAH (Kronik Obstrüktif Akciğer Hastalığı), akciğerlerde kalıcı hava akışı kısıtlamasıyla karakterize ilerleyici bir hastalıktır.

            **Nedenler:**
            • %85-90 sigara kullanımı
            • Uzun süreli kimyasal maruziyet
            • Hava kirliliği
            • Genetik faktörler (alfa-1 antitripsin eksikliği)

            **Belirtiler:**
            • Kronik öksürük ve balgam
            • Giderek artan nefes darlığı
            • Tekrarlayan akciğer enfeksiyonları
            • Hırıltılı solunum

            **Hastalığın Seyri:**
            GOLD evrelerine göre Evre 1'den 4'e kadar ilerler. Sigara bırakma ilerleyişi en etkili şekilde yavaşlatır.
            """
        ),
        HealthTip(
            icon: "cross.case",
            title: "Ne Zaman Doktora Gitmeliyim?",
            shortDesc: "Görmezden gelmemeniz gereken uyarı işaretleri.",
            detail: """
            Aşağıdaki belirtilerde zaman kaybetmeden doktora başvurun:

            **Acil Durum (112'yi arayın):**
            • Şiddetli nefes darlığı, konuşamama
            • Dudak veya tırnakların mavileşmesi
            • Göğüs ağrısı

            **Hızlı Tıbbi Değerlendirme:**
            • Kanlı balgam veya öksürük
            • 3 günden uzun süren yüksek ateş (38.5°C+)
            • Bilinç değişikliği veya konfüzyon

            **Rutin Değerlendirme:**
            • 3 haftadan uzun süren öksürük
            • Giderek artan nefes darlığı
            • Beklenmedik kilo kaybı
            • Gece terlemeleri
            """
        ),
        HealthTip(
            icon: "leaf",
            title: "Akciğer Sağlığı İpuçları",
            shortDesc: "Egzersiz, sigarasız yaşam ve hava kalitesi önerileri.",
            detail: """
            Akciğer sağlığınızı korumak için günlük hayatınıza entegre edebileceğiniz pratik öneriler:

            **Fiziksel Aktivite:**
            • Haftada en az 150 dakika orta yoğunluklu egzersiz
            • Yürüyüş, yüzme ve bisiklet akciğer kapasitesini artırır
            • Nefes egzersizleri (diyafram, pursed-lip) düzenli yapın

            **Sigaradan Uzak Durma:**
            • Sigara akciğer hasarını geri dönülemez yapabilir
            • Pasif sigara maruziyetinden de kaçının
            • Bırakmak için destek hattı: 182

            **Hava Kalitesi:**
            • Yoğun hava kirliliğinde dışarı çıkmayı kısıtlayın
            • Evde düzenli havalandırma yapın
            • Alerjen kaynaklarını azaltın (halı, perdeler temizliği)

            **Beslenme:**
            • Antioksidan zengin besinler (meyve, sebze, yeşil çay)
            • C vitamini ve omega-3 solunum sağlığını destekler
            """
        ),
    ]
}

// MARK: - Breathing Exercise

struct BreathingExercise: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let duration: Int
    let benefits: String
    let type: ExerciseType
    let color: String

    enum ExerciseType {
        case diaphragmatic
        case fourSevenEight
        case pursedLip
        case boxBreathing
        case controlledCough
    }

    static let all: [BreathingExercise] = [
        BreathingExercise(
            title: "Diyafram Nefesi",
            subtitle: "Temel Solunum Egzersizi",
            duration: 300,
            benefits: "Kaygıyı azaltır, solunum kaslarını güçlendirir ve akciğer kapasitesini artırır.",
            type: .diaphragmatic,
            color: "AppPrimary"
        ),
        BreathingExercise(
            title: "4-7-8 Nefes Tekniği",
            subtitle: "Stres Giderici",
            duration: 240,
            benefits: "Sinir sistemini sakinleştirir, uykuya geçişi kolaylaştırır, kan basıncını düzenler.",
            type: .fourSevenEight,
            color: "AppSuccess"
        ),
        BreathingExercise(
            title: "Büzük Dudak Nefesi",
            subtitle: "KOAH & Nefes Darlığı",
            duration: 300,
            benefits: "Nefes darlığını giderir, havayollarını açar. KOAH hastaları için özellikle faydalıdır.",
            type: .pursedLip,
            color: "AppWarning"
        ),
        BreathingExercise(
            title: "Kutu Nefesi",
            subtitle: "Konsantrasyon & Rahatlama",
            duration: 240,
            benefits: "Odaklanmayı artırır, stresi azaltır. Sporcular ve meditasyon uygulayıcıları tarafından kullanılır.",
            type: .boxBreathing,
            color: "AppPrimary"
        ),
        BreathingExercise(
            title: "Kontrollü Öksürük",
            subtitle: "Hava Yolu Temizleme",
            duration: 180,
            benefits: "Hava yollarındaki mukusu temizler. Kronik bronşit ve KOAH hastaları için önerilir.",
            type: .controlledCough,
            color: "AppDanger"
        ),
    ]
}
