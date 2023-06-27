import SwiftUI

struct PointingTooltipView: View {
    var text: String
    var tooltipDirection: TooltipDirection
    
    var themeConfig = defaultThemeConfig
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(text)
            .font(.system(size: themeConfig.current.annotationFontSize))
            .padding()
            .frame(width: 300, height: 150, alignment: .topLeading)
            .background(Color(themeConfig[colorScheme].tooltipBackgroundColor))
            .cornerRadius(10)
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.2), radius: 5)
    }

    enum TooltipDirection {
        case left
        case right
    }
}
