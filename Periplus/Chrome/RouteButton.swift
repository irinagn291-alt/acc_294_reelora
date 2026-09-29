import SwiftUI

/// Bordered prominent primary. Default, pressed, disabled, and loading.
/// The live verb wears accent. Opacity carries the press. There is no travel.
struct RoutePrimaryStyle: ButtonStyle {
    var loading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        RoutePrimaryBody(configuration: configuration, loading: loading)
    }
}

private struct RoutePrimaryBody: View {
    let configuration: ButtonStyleConfiguration
    var loading: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(RouteMeasure.mono(.body, weight: .semibold))
            .foregroundStyle(DesignTokens.bg)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous)
                    .fill(DesignTokens.accent)
                    .overlay {
                        RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous)
                            .strokeBorder(DesignTokens.ink.opacity(0.35), lineWidth: RouteMeasure.hairline)
                    }
            }
            .opacity(face)
            .overlay {
                if loading {
                    ProgressView()
                        .tint(DesignTokens.bg)
                }
            }
            .animation(RouteMeasure.settle, value: configuration.isPressed)
    }

    private var face: Double {
        if !isEnabled { return 0.38 }
        if configuration.isPressed { return 0.72 }
        return 1
    }
}

/// Reset and other destructive confirms. Accent stays on the live verb.
struct RouteDestructiveStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RouteDestructiveBody(configuration: configuration)
    }
}

private struct RouteDestructiveBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(RouteMeasure.mono(.body, weight: .semibold))
            .foregroundStyle(DesignTokens.ink)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous)
                    .fill(DesignTokens.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous)
                            .strokeBorder(DesignTokens.ink.opacity(0.7), lineWidth: RouteMeasure.hairline)
                    }
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.65 : 1) : 0.38)
    }
}

/// Secondary actions. Same chip radius and hairline fill as every other control.
struct RouteQuietStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RouteQuietBody(configuration: configuration)
    }
}

private struct RouteQuietBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(RouteMeasure.mono(.body, weight: .semibold))
            .foregroundStyle(DesignTokens.ink)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous)
                    .fill(DesignTokens.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous)
                            .strokeBorder(DesignTokens.muted.opacity(0.55), lineWidth: RouteMeasure.hairline)
                    }
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.65 : 1) : 0.38)
    }
}
