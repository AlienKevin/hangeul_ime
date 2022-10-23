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
        let annotationColor = selected
            ? themeConfig[colorScheme].selectedCodeColor
            : themeConfig[colorScheme].candidateCodeColor

        return HStack(alignment: .center, spacing: 2) {
            Text("\(index + 1).")
                .foregroundColor(Color(indexColor))
            Text(candidate.koreanWord)
                .foregroundColor(Color(textColor))
            Text(candidate.englishWords.joined(separator: ", "))
                .foregroundColor(Color(annotationColor))
        }
//        .fixedSize()
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

    var direction = CandidatesDirection.vertical
    var themeConfig = defaultThemeConfig
    @Environment(\.colorScheme) var colorScheme

    var _candidatesView: some View {
        ForEach(Array(candidates.enumerated()), id: \.element) { (index, candidate) -> CandidateView in
            CandidateView(
                candidate: candidate,
                index: index,
                origin: origin,
                selected: index == 0
            )
        }
    }

    var _indicator: some View {
        if direction == CandidatesDirection.horizontal {
            return AnyView(VStack(spacing: 0) {
                Image("arrowUp")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 10, height: 10, alignment: .center)
                    .onTapGesture {
                        if !hasPrev { return }
                        NotificationCenter.default.post(
                            name: State.prevPageBtnTapped,
                            object: nil
                        )
                    }
                    .foregroundColor(Color(hasPrev
                                     ? themeConfig[colorScheme].pageIndicatorColor
                                     : themeConfig[colorScheme].pageIndicatorDisabledColor
                    ))
                Image("arrowDown")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 10, height: 10, alignment: .center)
                    .onTapGesture {
                        if !hasNext { return }
                        print("next")
                        NotificationCenter.default.post(
                            name: State.nextPageBtnTapped,
                            object: nil
                        )
                    }
                    .foregroundColor(Color(hasNext
                                     ? themeConfig[colorScheme].pageIndicatorColor
                                     : themeConfig[colorScheme].pageIndicatorDisabledColor
                    ))
            })
        }
        return AnyView(HStack(spacing: 4) {
            Image("arrowUp")
                .renderingMode(.template)
                .resizable()
                .frame(width: 10, height: 10, alignment: .center)
                .rotationEffect(Angle(degrees: -90), anchor: .center)
                .onTapGesture {
                    if !hasPrev { return }
                    NotificationCenter.default.post(
                        name: State.prevPageBtnTapped,
                        object: nil
                    )
                }
            Image("arrowDown")
                .renderingMode(.template)
                .resizable()
                .frame(width: 10, height: 10, alignment: .center)
                .rotationEffect(Angle(degrees: -90), anchor: .center)
                .onTapGesture {
                    if !hasNext { return }
                    print("next")
                    NotificationCenter.default.post(
                        name: State.nextPageBtnTapped,
                        object: nil
                    )
                }
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat( themeConfig[colorScheme].originCandidatesSpace), content: {
            if direction == CandidatesDirection.horizontal {
                HStack(alignment: .center, spacing: CGFloat(themeConfig[colorScheme].candidateSpace)) {
                    _candidatesView
                    _indicator
                }
                .fixedSize()
            } else {
                VStack(alignment: .leading, spacing: CGFloat(themeConfig[colorScheme].candidateSpace)) {
                    _candidatesView
                    _indicator
                }
                .fixedSize()
            }
        })
            .padding(.top, CGFloat(themeConfig[colorScheme].windowPaddingTop))
            .padding(.bottom, CGFloat(themeConfig[colorScheme].windowPaddingBottom))
            .padding(.leading, CGFloat(themeConfig[colorScheme].windowPaddingLeft))
            .padding(.trailing, CGFloat(themeConfig[colorScheme].windowPaddingRight))
            .fixedSize()
            .font(.system(size: CGFloat(themeConfig[colorScheme].fontSize)))
            .background(Color(themeConfig[colorScheme].windowBackgroundColor))
            .cornerRadius(CGFloat(themeConfig[colorScheme].windowBorderRadius), antialiased: true)
    }
}
