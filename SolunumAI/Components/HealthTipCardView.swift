import SwiftUI

struct HealthTipCardView: View {
    let tip: HealthTip
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    // Icon badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("AppPrimary").opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: tip.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color("AppPrimary"))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(tip.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(tip.shortDesc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                ScrollView {
                    Text(LocalizedStringKey(tip.detail))
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 280)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Horizontal scroll card (for Home tab)

struct HealthTipHScrollCard: View {
    let tip: HealthTip
    @State private var isPresented = false

    var body: some View {
        Button { isPresented = true } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AppPrimary").opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: tip.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color("AppPrimary"))
                }

                Text(tip.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(tip.shortDesc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                Spacer()

                Text("Devamını Oku →")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color("AppPrimary"))
            }
            .padding(16)
            .frame(width: 170, height: 200)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            HealthTipDetailSheet(tip: tip)
        }
    }
}

// MARK: - Detail sheet

struct HealthTipDetailSheet: View {
    let tip: HealthTip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("AppPrimary").opacity(0.12))
                                .frame(width: 60, height: 60)
                            Image(systemName: tip.icon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(Color("AppPrimary"))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tip.title)
                                .font(.title2.weight(.bold))
                            Text(tip.shortDesc)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }

                    Divider()

                    Text(LocalizedStringKey(tip.detail))
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
            }
            .navigationTitle(tip.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(HealthTip.all) { tip in
                HealthTipCardView(tip: tip)
            }
        }
        .padding()
    }
    .background(Color("AppBackground"))
}
