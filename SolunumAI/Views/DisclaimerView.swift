import SwiftUI

struct DisclaimerView: View {
    let onAccept: () -> Void

    @State private var scrolledToBottom = false
    @State private var checked = false

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ──────────────────────────────────────────────
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color("AppPrimary").opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundColor(Color("AppPrimary"))
                    }
                    .padding(.top, 48)

                    Text("Önemli Bilgilendirme")
                        .font(.title2.weight(.bold))

                    Text("Lütfen uygulamayı kullanmadan önce okuyun")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 24)

                // ── Scrollable content ───────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        DisclaimerBlock(
                            icon: "stethoscope",
                            iconColor: Color("AppDanger"),
                            title: "Tıbbi Tanı Değildir",
                            bodyText: "SolunumAI, öksürük seslerini yapay zeka ile analiz ederek genel bir risk değerlendirmesi sunar. Bu uygulama hiçbir koşulda doktor muayenesi, tıbbi tanı veya tedavi yerine geçmez."
                        )

                        DisclaimerBlock(
                            icon: "person.fill.questionmark",
                            iconColor: Color("AppWarning"),
                            title: "Uzman Görüşü Alın",
                            bodyText: "Herhangi bir solunum semptomu, öksürük veya sağlık sorununuz için mutlaka bir sağlık profesyoneline başvurun. Analiz sonuçlarını kendi kendinize teşhis amacıyla kullanmayın."
                        )

                        DisclaimerBlock(
                            icon: "chart.bar.doc.horizontal",
                            iconColor: Color("AppPrimary"),
                            title: "Sonuçlar Kesin Değildir",
                            bodyText: "Yapay zeka modelleri %100 doğruluk garantisi vermez. Ses kalitesi, kayıt koşulları ve bireysel farklılıklar sonuçları etkileyebilir. Düşük risk skoru sağlıklı olduğunuz anlamına gelmez."
                        )

                        DisclaimerBlock(
                            icon: "lock.shield.fill",
                            iconColor: Color("AppSuccess"),
                            title: "Verileriniz Güvende",
                            bodyText: "Kaydettiğiniz ses ve analiz sonuçları yalnızca cihazınızda ve yerel sunucuda işlenir. Üçüncü şahıslarla paylaşılmaz."
                        )

                        // Acil uyarı kutusu
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                            Text("Nefes darlığı, göğüs ağrısı veya ani kötüleşme durumunda hemen 112'yi arayın.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(Color("AppDanger"))
                        .cornerRadius(14)

                        // Spacer for bottom detection
                        Color.clear
                            .frame(height: 1)
                            .onAppear { scrolledToBottom = true }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }

                // ── Bottom area ──────────────────────────────────────────
                VStack(spacing: 16) {
                    Divider()

                    // Checkbox
                    Button {
                        withAnimation(.spring(response: 0.3)) { checked.toggle() }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(checked ? Color("AppPrimary") : Color(.systemGray3), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                if checked {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color("AppPrimary"))
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            Text("Yukarıdakileri okudum ve anladım. Bu uygulamanın tıbbi tanı aracı olmadığını kabul ediyorum.")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)

                    // Accept button
                    Button {
                        onAccept()
                    } label: {
                        Text("Anladım, Devam Et")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(checked ? Color("AppPrimary") : Color(.systemGray4))
                            .cornerRadius(14)
                            .animation(.easeInOut(duration: 0.2), value: checked)
                    }
                    .disabled(!checked)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .background(Color(.systemBackground))
            }
        }
    }
}

// MARK: - Disclaimer Block

private struct DisclaimerBlock: View {
    let icon: String
    let iconColor: Color
    let title: String
    let bodyText: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(bodyText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6)
    }
}

#Preview {
    DisclaimerView(onAccept: {})
}
