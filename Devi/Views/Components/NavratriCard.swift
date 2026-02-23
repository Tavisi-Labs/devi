// MARK: - Views/Components/NavratriCard.swift
// Special card shown during Navratri periods

import SwiftUI

struct NavratriCard: View {
    let day: NavratriDay
    let theme: DeviTheme
    
    @State private var isAppearing = false
    
    private var dayColor: Color {
        Color(hex: day.colorHex)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: day indicator
            HStack {
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundColor(dayColor)
                
                Text("NAVRATRI DAY \(day.dayNumber)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(dayColor)
                    .tracking(2)
                
                Spacer()
                
                // Day dots (9 dots, filled up to current day)
                HStack(spacing: 4) {
                    ForEach(1...9, id: \.self) { num in
                        Circle()
                            .fill(num <= day.dayNumber ? dayColor : theme.primaryText.opacity(0.2))
                            .frame(width: 5, height: 5)
                    }
                }
            }
            
            // Goddess name
            VStack(alignment: .leading, spacing: 4) {
                Text(day.goddessName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                
                Text(day.goddessEpithet)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(theme.secondaryText)
            }
            
            // Color and offering
            HStack(spacing: 24) {
                // Color to wear
                HStack(spacing: 8) {
                    Circle()
                        .fill(dayColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(theme.primaryText.opacity(0.3), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("WEAR")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(theme.secondaryText)
                            .tracking(1)
                        Text(day.colorName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.primaryText)
                    }
                }
                
                // Offering
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                        .foregroundColor(dayColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("OFFERING")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(theme.secondaryText)
                            .tracking(1)
                        Text(day.offering)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.primaryText)
                    }
                }
            }
            
            // Mantra
            VStack(alignment: .leading, spacing: 6) {
                Divider()
                    .background(theme.primaryText.opacity(0.1))
                
                Text(day.mantra)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(theme.primaryText.opacity(0.9))
                    .lineSpacing(4)
                
                Text(day.mantraTranslit)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(theme.secondaryText)
                    .italic()
            }
        }
        .padding(20)
        .background(
            ZStack {
                // Card background
                theme.cardBackground
                
                // Subtle inner glow from the day's color
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(dayColor.opacity(0.2), lineWidth: 1)
                
                // Corner accent glow
                RadialGradient(
                    colors: [dayColor.opacity(0.08), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 200
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .offset(y: isAppearing ? 0 : 20)
        .opacity(isAppearing ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "4a1942").ignoresSafeArea()
        
        NavratriCard(
            day: NavratriDay.chaitraNavratri2026[4], // Day 5 - Skandamata
            theme: DeviTheme.forPeriod(.evening)
        )
        .padding()
    }
}
