import SwiftUI

struct PointingTooltipView: View {
    var word: String
    var explanations: [Explanation]
    var derivedPr: String
    var tooltipDirection: TooltipDirection
    
    var themeConfig = defaultThemeConfig
    @Environment(\.colorScheme) var colorScheme
    
    func highlightDiff(word: String, nextWord: String) -> Text {
        var highlightedText = Text("")
        
        let chars = Array(word)
        let nextChars = Array(nextWord)
        
        for (char, nextChar) in zip(chars, nextChars) {
            if char != nextChar {
                highlightedText = highlightedText + Text(String(char)).foregroundColor(Color(themeConfig[colorScheme].tooltipSelectedTextColor))
            } else {
                highlightedText = highlightedText + Text(String(char))
            }
        }
        
        return highlightedText
    }

    var body: some View {
        let content = explanations.enumerated().reduce(Text("")) { (result, element) in
            let (i, t) = element
            let indexText = Text("\(i + 1) ")
                .font(.system(size: themeConfig[colorScheme].annotationFontSize, design: .monospaced))
                .foregroundColor(Color(themeConfig[colorScheme].candidateIndexColor))
            let wordText = i == 0 ?
                highlightDiff(
                    word: word,
                    nextWord: explanations[0].result)
            : highlightDiff(
                    word: explanations[i - 1].result,
                    nextWord: explanations[i].result)
            let patternText = Text(t.pattern).font(.system(size: themeConfig[colorScheme].annotationFontSize))
            let templateText =  Text(" → " + t.template + "\n").font(.system(size: themeConfig[colorScheme].annotationFontSize))
            return result + indexText + wordText + Text(" ") + patternText + templateText
        }
        let result = Text("\(explanations.count + 1) ")
            .font(.system(size: themeConfig[colorScheme].annotationFontSize, design: .monospaced))
            .foregroundColor(Color(themeConfig[colorScheme].candidateIndexColor))
                + Text(derivedPr)
        (content + result)
            .font(.system(size: CGFloat(themeConfig[colorScheme].fontSize), design: .monospaced))
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
