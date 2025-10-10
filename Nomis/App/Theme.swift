import SwiftUI

// MARK: - Color Extension for Dark Mode Support
extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor(dynamicProvider: { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        }))
    }
}

struct NomisTheme {
    // MARK: - Colors (Rolex inspired luxury palette) - Now with Dark Mode support
    static let primaryGreen = Color(light: Color(red: 0.004, green: 0.341, blue: 0.235), 
                                     dark: Color(red: 0.1, green: 0.5, blue: 0.35))
    static let goldAccent = Color(light: Color(red: 1.0, green: 0.788, blue: 0.055), 
                                   dark: Color(red: 1.0, green: 0.85, blue: 0.3))
    static let creamBackground = Color(light: Color(red: 0.988, green: 0.984, blue: 0.976), 
                                        dark: Color(red: 0.1, green: 0.1, blue: 0.1))
    static let lightCream = Color(light: Color(red: 0.996, green: 0.992, blue: 0.988), 
                                   dark: Color(red: 0.15, green: 0.15, blue: 0.15))
    static let darkText = Color(light: Color(red: 0.133, green: 0.133, blue: 0.133), 
                                 dark: Color(red: 0.9, green: 0.9, blue: 0.9))
    static let borderGray = Color(light: Color(red: 0.627, green: 0.627, blue: 0.627), 
                                   dark: Color(red: 0.4, green: 0.4, blue: 0.4))
    static let shadowColor = Color(light: Color.black.opacity(0.12), 
                                    dark: Color.black.opacity(0.4))
    
    // MARK: - Premium accent colors
    static let platinumGray = Color(light: Color(red: 0.706, green: 0.706, blue: 0.706), 
                                     dark: Color(red: 0.5, green: 0.5, blue: 0.5))
    static let champagneGold = Color(light: Color(red: 0.976, green: 0.918, blue: 0.722), 
                                      dark: Color(red: 0.8, green: 0.75, blue: 0.5))
    static let blackNight = Color(light: Color(red: 0.067, green: 0.067, blue: 0.067), 
                                   dark: Color(red: 0.9, green: 0.9, blue: 0.9))
    
    // MARK: - Semantic Colors
    static let background = creamBackground
    static let cardBackground = lightCream
    static let primary = primaryGreen
    static let accent = goldAccent
    static let text = darkText
    static let secondary = Color(light: Color(red: 0.4, green: 0.4, blue: 0.4), 
                                  dark: Color(red: 0.7, green: 0.7, blue: 0.7))
    static let secondaryText = Color(light: Color(red: 0.4, green: 0.4, blue: 0.4), 
                                      dark: Color(red: 0.7, green: 0.7, blue: 0.7))
    static let border = borderGray
    static let destructive = Color(light: Color(red: 0.8, green: 0.2, blue: 0.2), 
                                    dark: Color(red: 1.0, green: 0.3, blue: 0.3))
    static let shadow = shadowColor
    
    // MARK: - Enhanced Visibility Colors
    static let prominentText = Color(light: Color(red: 0.067, green: 0.067, blue: 0.067), 
                                      dark: Color(red: 1.0, green: 1.0, blue: 1.0))
    static let ayarHighlight = primaryGreen
    
    // MARK: - Spacing (Luxury proportions)
    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 16
    static let fieldCornerRadius: CGFloat = 12
    static let cornerRadius: CGFloat = 8
    static let cardSpacing: CGFloat = 24
    static let contentSpacing: CGFloat = 20
    static let smallSpacing: CGFloat = 12
    static let tinySpacing: CGFloat = 6
    static let largeSpacing: CGFloat = 32
    static let extraLargeSpacing: CGFloat = 40
    static let sectionSpacing: CGFloat = 20
    static let itemSpacing: CGFloat = 12
    
    // MARK: - Table dimensions (Consistent sizing)
    static let tableHeaderHeight: CGFloat = 60
    static let tableCellHeight: CGFloat = 55
    static let tableBorderWidth: CGFloat = 3.5
    static let tableCornerRadius: CGFloat = 8
    
    // MARK: - Shadow (Premium depth)
    static let cardShadow: Color = shadowColor
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowOffset: CGSize = CGSize(width: 0, height: 4)
    static let tableShadowRadius: CGFloat = 8
    static let tableShadowOffset: CGSize = CGSize(width: 0, height: 2)
    
    // MARK: - Font Weights (Rolex typography hierarchy)
    static let titleWeight: Font.Weight = .bold
    static let headlineWeight: Font.Weight = .semibold
    static let bodyWeight: Font.Weight = .medium
    static let captionWeight: Font.Weight = .regular
    
    // MARK: - Font Sizes
    static let largeTitleSize: CGFloat = 32
    static let titleSize: CGFloat = 24
    static let headlineSize: CGFloat = 18
    static let bodySize: CGFloat = 16
    static let captionSize: CGFloat = 14
}

// Legacy Theme struct for backward compatibility
struct Theme {
    static let background = NomisTheme.background
    static let cardBackground = NomisTheme.cardBackground
    static let primary = NomisTheme.primary
    static let accent = NomisTheme.accent
    static let text = NomisTheme.text
    static let secondaryText = NomisTheme.secondaryText
    static let border = NomisTheme.border
    static let destructive = NomisTheme.destructive
    static let cardCornerRadius = NomisTheme.cardCornerRadius
    static let buttonCornerRadius = NomisTheme.buttonCornerRadius
    static let fieldCornerRadius = NomisTheme.fieldCornerRadius
    static let cardSpacing = NomisTheme.cardSpacing
    static let contentSpacing = NomisTheme.contentSpacing
    static let smallSpacing = NomisTheme.smallSpacing
    static let largeSpacing = NomisTheme.largeSpacing
    static let cardShadow = NomisTheme.cardShadow
    static let cardShadowRadius = NomisTheme.cardShadowRadius
    static let cardShadowOffset = NomisTheme.cardShadowOffset
    static let titleWeight = NomisTheme.titleWeight
    static let headlineWeight = NomisTheme.headlineWeight
    static let bodyWeight = NomisTheme.bodyWeight
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(NomisTheme.cardBackground)
            .cornerRadius(NomisTheme.cardCornerRadius)
            .shadow(color: NomisTheme.cardShadow, radius: NomisTheme.cardShadowRadius, x: NomisTheme.cardShadowOffset.width, y: NomisTheme.cardShadowOffset.height)
    }
    
    func nomisCard() -> some View {
        self.modifier(NomisCardStyle())
    }
    
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, NomisTheme.contentSpacing)
            .padding(.vertical, 12)
            .background(NomisTheme.primary)
            .cornerRadius(NomisTheme.buttonCornerRadius)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .foregroundColor(NomisTheme.primary)
            .padding(.horizontal, NomisTheme.contentSpacing)
            .padding(.vertical, 12)
            .background(NomisTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: NomisTheme.buttonCornerRadius)
                    .stroke(NomisTheme.primary, lineWidth: 1)
            )
    }
    
    func destructiveButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, NomisTheme.contentSpacing)
            .padding(.vertical, 12)
            .background(NomisTheme.destructive)
            .cornerRadius(NomisTheme.buttonCornerRadius)
    }
    
    func textFieldStyle() -> some View {
        self
            .padding(12)
            .background(NomisTheme.cardBackground)
            .cornerRadius(NomisTheme.fieldCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: NomisTheme.fieldCornerRadius)
                    .stroke(NomisTheme.border, lineWidth: 1)
            )
    }
    
    func tableRowStyle() -> some View {
        self
            .padding(.horizontal, NomisTheme.contentSpacing)
            .padding(.vertical, NomisTheme.smallSpacing)
            .background(NomisTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(NomisTheme.border, lineWidth: NomisTheme.tableBorderWidth)
            )
    }
    
    // MARK: - Premium Table Styles
    func luxuryTableHeader() -> some View {
        self
            .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
            .foregroundColor(NomisTheme.blackNight)
            .frame(height: NomisTheme.tableHeaderHeight)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [NomisTheme.champagneGold.opacity(0.3), NomisTheme.goldAccent.opacity(0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Rectangle()
                    .stroke(NomisTheme.primaryGreen, lineWidth: NomisTheme.tableBorderWidth)
            )
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(NomisTheme.primaryGreen)
                        .frame(height: 2)
                }
            )
    }
    
    func luxuryTableCell(showBorder: Bool = true) -> some View {
        self
            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
            .foregroundColor(NomisTheme.darkText)
            .frame(height: NomisTheme.tableCellHeight)
            .frame(maxWidth: .infinity)
            .background(NomisTheme.lightCream)
            .overlay(
                showBorder ? 
                Rectangle()
                    .stroke(NomisTheme.borderGray, lineWidth: NomisTheme.tableBorderWidth) :
                nil
            )
    }
    
    func luxuryTableContainer() -> some View {
        self
            .background(NomisTheme.cardBackground)
            .cornerRadius(0)
            .shadow(
                color: NomisTheme.shadowColor,
                radius: NomisTheme.tableShadowRadius,
                x: NomisTheme.tableShadowOffset.width,
                y: NomisTheme.tableShadowOffset.height
            )
            .overlay(
                Rectangle()
                    .stroke(NomisTheme.primaryGreen.opacity(0.5), lineWidth: 2)
            )
    }
    
    func sectionHeaderStyle() -> some View {
        self
            .font(.headline.weight(NomisTheme.headlineWeight))
            .foregroundColor(NomisTheme.text)
            .padding(.horizontal, NomisTheme.contentSpacing)
            .padding(.vertical, NomisTheme.smallSpacing)
    }
}

struct NomisCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(NomisTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: NomisTheme.shadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, NomisTheme.contentSpacing)
            .padding(.vertical, 12)
            .background(NomisTheme.primary.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(NomisTheme.buttonCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(NomisTheme.primary)
            .padding(.horizontal, NomisTheme.contentSpacing)
            .padding(.vertical, 12)
            .background(NomisTheme.cardBackground.opacity(configuration.isPressed ? 0.8 : 1.0))
            .overlay(
                RoundedRectangle(cornerRadius: NomisTheme.buttonCornerRadius)
                    .stroke(NomisTheme.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, NomisTheme.contentSpacing)
            .padding(.vertical, 12)
            .background(NomisTheme.destructive.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(NomisTheme.buttonCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - New NomisButtonStyle
struct NomisButtonStyle: ButtonStyle {
    enum Style {
        case primary
        case secondary
        case destructive
    }
    
    let style: Style
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return NomisTheme.accent
        case .secondary:
            return NomisTheme.cardBackground
        case .destructive:
            return Color.red.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return NomisTheme.primary
        case .destructive:
            return .red
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return NomisTheme.accent
        case .secondary:
            return NomisTheme.accent.opacity(0.3)
        case .destructive:
            return Color.red.opacity(0.3)
        }
    }
}
