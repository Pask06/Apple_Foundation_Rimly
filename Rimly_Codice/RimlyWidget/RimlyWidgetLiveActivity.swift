import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Liquid Glass Lock Screen Background
struct RimlyLiquidGlassBackground: View {
    var body: some View {
        ZStack {
            // Base scura
            ThemeColors.surface.ignoresSafeArea()

            // Blob azzurro in alto-sinistra
            Circle()
                .fill(ThemeColors.primary)
                .frame(width: 160, height: 160)
                .blur(radius: 50)
                .opacity(0.45)
                .offset(x: -60, y: -40)

            // Blob arancione in basso-destra
            Circle()
                .fill(ThemeColors.tertiary)
                .frame(width: 120, height: 120)
                .blur(radius: 40)
                .opacity(0.30)
                .offset(x: 80, y: 30)

            // Vetro nativo Apple
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.45), .clear, .white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Progress Bar Component
struct RimlyProgressBar: View {
    let progress: Double // 0.0 → 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(height: 4)

                // Fill (azzurro primary)
                Capsule()
                    .fill(ThemeColors.primary)
                    .frame(width: geo.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Widget Config
struct RimlyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RimlyTimerAttributes.self) { context in

            // ============================================================
            // LOCK SCREEN LIVE ACTIVITY — Matches your mockup exactly
            // ============================================================
            ZStack {
                RimlyLiquidGlassBackground()

                VStack(alignment: .leading, spacing: 14) {

                    // Row 1: Large countdown (left) + Stop button (right)
                    HStack(alignment: .center) {

                        // Big countdown — stile identico al mockup (bold, bianco)
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)

                        Spacer()
                    }

                    // Row 2: Progress bar
                    RimlyProgressBar(progress: context.state.progress)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .cornerRadius(26)
            

        } dynamicIsland: { context in

            // ============================================================
            // DYNAMIC ISLAND
            // ============================================================
            DynamicIsland {

                // LEADING — "Rimly" + countdown (come nel mockup: "Breathe 10:00")
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rimly")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeColors.primary)

                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 4)
                }

                // TRAILING — Stop button arancione (esatto come il mockup)
                DynamicIslandExpandedRegion(.trailing) {
                    Link(destination: URL(string: "rimly://stop")!) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ThemeColors.tertiary)
                                .frame(width: 44, height: 44)

                            Image(systemName: "stop.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 4)
                }

                // BOTTOM — Bowl name
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.bowlName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 2)
                }

            } compactLeading: {
                Image(systemName: "bell.fill")
                    .foregroundColor(ThemeColors.tertiary)
                    .font(.caption)

            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .frame(width: 42)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.white)

            } minimal: {
                Image(systemName: "bell.fill")
                    .foregroundColor(ThemeColors.tertiary)
            }
        }
    }
}
