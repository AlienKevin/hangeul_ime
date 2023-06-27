//
//  CandidatesView.swift
//  Hangeul
//
//  Created by Kevin Li on 10/23/22.
//  src: https://github.com/qwertyyb/Fire/blob/master/Fire/CandidatesView.swift

import SwiftUI

struct CandidateView: View {
    var candidate: Candidate
    var index: Int
    var origin: String
    var selected: Bool = false

    var themeConfig = defaultThemeConfig
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let indexColor = selected
            ? themeConfig[colorScheme].selectedIndexColor
            : themeConfig[colorScheme].candidateIndexColor
        let textColor = selected
            ? themeConfig[colorScheme].selectedTextColor
            : themeConfig[colorScheme].candidateTextColor
        let backgroundColor = selected
            ? themeConfig[colorScheme].selectedBackgroundColor
            : themeConfig[colorScheme].candidateBackgroundColor
        let annotationColor = selected
            ? themeConfig[colorScheme].selectedCodeColor
            : themeConfig[colorScheme].candidateCodeColor
        
        return HStack(alignment: .center, spacing: 4) {
            Text("\(index + 1)")
                .foregroundColor(Color(indexColor))
                .font(.system(size: themeConfig.current.annotationFontSize))
            Text(candidate.koreanWord)
                .lineLimit(1)
                .foregroundColor(Color(textColor))
                .background(RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(backgroundColor)))
            Text(candidate.englishWords.joined(separator: ", "))
                .lineLimit(1)
                .foregroundColor(Color(annotationColor))
                .font(.system(size: themeConfig.current.annotationFontSize))
        }
        .onTapGesture {
            NotificationCenter.default.post(
                name: State.candidateSelected,
                object: nil,
                userInfo: [
                    "candidate": candidate,
                    "index": index
                ]
            )
        }
    }
}

struct CandidatesView: View {
    var candidates: [Candidate]
    var origin: String
    var hasPrev: Bool = false
    var hasNext: Bool = false
    var selectedIndex: Int = 0

    var direction = CandidatesDirection.vertical
    var themeConfig = defaultThemeConfig
    @Environment(\.colorScheme) var colorScheme

    var _candidatesView: some View {
        ForEach(Array(candidates.enumerated()), id: \.element) { (index, candidate) -> CandidateView in
            CandidateView(
                candidate: candidate,
                index: index,
                origin: origin,
                selected: index == selectedIndex
            )
        }
    }

    var _indicator: some View {
        let arrowUp = getIndicatorIcon(imageName: "arrowUp", direction: direction, activeFlag: hasPrev, eventName: State.prevPageBtnTapped)
        let arrowDown = getIndicatorIcon(imageName: "arrowDown", direction: direction, activeFlag: hasNext, eventName: State.nextPageBtnTapped)
        if direction == CandidatesDirection.horizontal {
            return AnyView(VStack(spacing: 0) { arrowUp; arrowDown })
        } else {
            return AnyView(HStack(spacing: 4) { arrowUp; arrowDown })
        }
    }
    
    func getIndicatorIcon(imageName: String, direction: CandidatesDirection, activeFlag: Bool, eventName: Notification.Name) -> some View {
        return Image(imageName)
            .renderingMode(.template)
            .resizable()
            .frame(width: 10, height: 10, alignment: .center)
            .rotationEffect(Angle(degrees: direction == CandidatesDirection.horizontal ? 0 : -90), anchor: .center)
            .onTapGesture {
                if !activeFlag { return }
                NotificationCenter.default.post(
                    name: eventName,
                    object: nil
                )
            }
            .foregroundColor(Color(activeFlag
                                   ? themeConfig[colorScheme].pageIndicatorColor
                                   : themeConfig[colorScheme].pageIndicatorDisabledColor
                                  ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat( themeConfig[colorScheme].originCandidatesSpace), content: {
            if direction == CandidatesDirection.horizontal {
                HStack(alignment: .center, spacing: CGFloat(themeConfig[colorScheme].candidateSpace)) {
                    _candidatesView
                    _indicator
                }
            } else {
                VStack(alignment: .leading, spacing: CGFloat(themeConfig[colorScheme].candidateSpace)) {
                    _candidatesView
                    Spacer()
                    _indicator
                }
            }
        })
            .padding(.top, CGFloat(themeConfig[colorScheme].windowPaddingTop))
            .padding(.bottom, CGFloat(themeConfig[colorScheme].windowPaddingBottom))
            .padding(.leading, CGFloat(themeConfig[colorScheme].windowPaddingLeft))
            .padding(.trailing, CGFloat(themeConfig[colorScheme].windowPaddingRight))
            .frame(width: 200, height: 200, alignment: .topLeading)
            .font(.system(size: CGFloat(themeConfig[colorScheme].fontSize)))
            .background(Color(themeConfig[colorScheme].windowBackgroundColor))
            .cornerRadius(CGFloat(themeConfig[colorScheme].windowBorderRadius), antialiased: true)
    }
}
