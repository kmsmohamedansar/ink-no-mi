import SwiftUI

struct FlowDeskFirstRunOnboardingView: View {
    struct OnboardingPage: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let symbol: String
    }

    private let pages: [OnboardingPage] = [
        .init(
            title: "Think visually",
            subtitle: "Create whiteboards, diagrams, notes, and planning boards in one calm workspace.",
            symbol: "square.on.circle"
        ),
        .init(
            title: "Start from structure",
            subtitle: "Use templates for brainstorming, roadmaps, flowcharts, meeting notes, and more.",
            symbol: "square.grid.2x2"
        ),
        .init(
            title: "Make it yours",
            subtitle: "Customize themes, fonts, canvas style, and workspace feel.",
            symbol: "paintbrush.pointed"
        )
    ]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pageIndex = 0
    @State private var animateIcon = false

    let onSkip: () -> Void
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            VStack(spacing: FlowDeskLayout.spaceXL) {
                HStack {
                    Spacer()
                    Button("Skip", action: onSkip)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, FlowDeskLayout.spaceS)
                        .padding(.vertical, FlowDeskLayout.spaceXS)
                        .background {
                            Capsule()
                                .fill(.quaternary.opacity(0.5))
                        }
                }

                Spacer(minLength: 0)

                cardView(for: pages[pageIndex])
                    .id(pages[pageIndex].id)
                    .transition(cardTransition)
                    .animation(animationStyle, value: pageIndex)

                pageDots

                actionButton

                Spacer(minLength: FlowDeskLayout.spaceL)
            }
            .padding(FlowDeskLayout.spaceXL)
            .frame(maxWidth: 620)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                FlowDeskMotion.slowEaseInOut
                .repeatForever(autoreverses: true)
            ) {
                animateIcon = true
            }
        }
    }

    private var cardTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
    }

    private var animationStyle: Animation? {
        reduceMotion ? nil : FlowDeskMotion.slowEaseOut
    }

    @ViewBuilder
    private func cardView(for page: OnboardingPage) -> some View {
        VStack(spacing: FlowDeskLayout.spaceL) {
            Image(systemName: page.symbol)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(FlowDeskLayout.spaceM)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.quaternary.opacity(0.35))
                }
                .scaleEffect(animateIcon ? 1.03 : 0.98)

            VStack(spacing: FlowDeskLayout.spaceS) {
                Text(page.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }
        }
        .padding(FlowDeskLayout.spaceXL)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.quaternary.opacity(0.55), lineWidth: 1)
                }
        }
    }

    private var pageDots: some View {
        HStack(spacing: FlowDeskLayout.spaceS) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, _ in
                Circle()
                    .fill(index == pageIndex ? Color.primary.opacity(0.7) : Color.secondary.opacity(0.25))
                    .frame(width: 7, height: 7)
                    .scaleEffect(index == pageIndex ? 1.2 : 1.0)
                    .animation(animationStyle, value: pageIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Step \(pageIndex + 1) of \(pages.count)")
    }

    private var actionButton: some View {
        Button(buttonTitle) {
            if pageIndex == pages.count - 1 {
                onFinish()
            } else {
                withAnimation(animationStyle) {
                    pageIndex += 1
                }
            }
        }
        .buttonStyle(FlowDeskHomeCardButtonStyle())
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(DS.Color.premiumBlueGradient)
        )
        .keyboardShortcut(.defaultAction)
    }

    private var buttonTitle: String {
        pageIndex == pages.count - 1 ? "Start creating" : "Continue"
    }
}
