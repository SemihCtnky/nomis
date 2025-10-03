import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.buttonWeight))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: NomisTheme.cornerRadius)
                    .fill(configuration.isPressed ? NomisTheme.primaryGreen.opacity(0.8) : NomisTheme.primaryGreen)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.buttonWeight))
            .foregroundColor(NomisTheme.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: NomisTheme.cornerRadius)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: NomisTheme.cornerRadius)
                            .stroke(configuration.isPressed ? NomisTheme.primary.opacity(0.8) : NomisTheme.primary, lineWidth: 2)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.buttonWeight))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: NomisTheme.cornerRadius)
                    .fill(configuration.isPressed ? NomisTheme.destructive.opacity(0.8) : NomisTheme.destructive)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CancelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.buttonWeight))
            .foregroundColor(NomisTheme.secondaryText)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: NomisTheme.cornerRadius)
                    .fill(configuration.isPressed ? NomisTheme.lightGray.opacity(0.8) : NomisTheme.lightGray)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
