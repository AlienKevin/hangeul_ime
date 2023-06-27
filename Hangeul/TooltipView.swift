import SwiftUI

struct PointingTooltipView: View {
    var text: Text
    var tooltipDirection: TooltipDirection
    
    var themeConfig = defaultThemeConfig
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        text
            .padding()
            .frame(width: 250, height: 200, alignment: .topLeading)
            .background(Color(themeConfig[colorScheme].tooltipBackgroundColor))
            .cornerRadius(10)
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.2), radius: 5)
    }

    enum TooltipDirection {
        case left
        case right
    }
}
