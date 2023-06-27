//
//  ThemeConfig.swift
//  Hangeul
//
//  Created by Kevin Li on 10/23/22.
//  src: https://github.com/qwertyyb/Fire/blob/b01d305cbc356c588d6f47db84294e2b2181c918/Fire/Theme/ThemeConfig.swift

import Foundation
import AppKit
import SwiftUI

struct ColorData: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    func withOpacity(opacity: Double) -> ColorData {
        ColorData(red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension Color {
    init(_ colorData: ColorData) {
        self.init(
            Color.RGBColorSpace.sRGB,
            red: colorData.red,
            green: colorData.green,
            blue: colorData.blue,
            opacity: colorData.opacity
        )
    }
}

struct ApperanceThemeConfig: Codable {
    let windowBackgroundColor: ColorData
    let windowPaddingTop: Float
    let windowPaddingLeft: Float
    let windowPaddingRight: Float
    let windowPaddingBottom: Float
    let windowBorderRadius: Float

    let originCodeColor: ColorData
    let originCandidatesSpace: Float
    let candidateSpace: Float

    let candidateIndexColor: ColorData
    let candidateTextColor: ColorData
    let candidateCodeColor: ColorData
    let candidateBackgroundColor: ColorData
    
    let tooltipBackgroundColor: ColorData
    let tooltipSelectedTextColor: ColorData

    let selectedIndexColor: ColorData
    let selectedTextColor: ColorData
    let selectedCodeColor: ColorData
    let selectedBackgroundColor: ColorData

    // 页面指示器颜色
    let pageIndicatorColor: ColorData
    // 页面指示器置灰色
    let pageIndicatorDisabledColor: ColorData

    let fontName: String
    let fontSize: Float
    let annotationFontSize: CGFloat
}

struct ThemeConfig: Codable {
    let id: String
    let name: String
    let author: String

    let light: ApperanceThemeConfig
    let dark: ApperanceThemeConfig?

    var current: ApperanceThemeConfig {
        light
    }

    subscript(colorScheme: ColorScheme) -> ApperanceThemeConfig {
        if let dark = self.dark, colorScheme == .dark {
            return dark
        }
        return light
    }
}

let defaultLightAccentColor = ColorData(red: 0, green: 80/255, blue: 180/255, opacity: 1)
let defaultLightBackgroundColor = ColorData(red: 1, green: 1, blue: 1, opacity: 1)
let defaultLightGreyColor = ColorData(red: 0.9451, green: 0.9176, blue: 0.8902, opacity: 1)

let defaultDarkAccentColor = ColorData(red: 0.947, green: 0.184, blue: 0.243, opacity: 1)
let defaultDarkBackgroundColor = ColorData(red: 0, green: 0, blue: 0, opacity: 1)
let defaultDarkGreyColor = ColorData(red: 0.2235, green: 0.1569, blue: 0.1373, opacity: 1)

let defaultThemeConfig = ThemeConfig(
    id: "default",
    name: "default",
    author: "Kevin Li",
    light: ApperanceThemeConfig(
        windowBackgroundColor: defaultLightBackgroundColor,
        windowPaddingTop: 6,
        windowPaddingLeft: 10,
        windowPaddingRight: 10,
        windowPaddingBottom: 6,
        windowBorderRadius: 6,
        originCodeColor: ColorData(red: 0.3, green: 0.3, blue: 0.3, opacity: 1),
        originCandidatesSpace: 6,
        candidateSpace: 8,
        candidateIndexColor: ColorData(red: 0.6, green: 0.6, blue: 0.6, opacity: 1),
        candidateTextColor: ColorData(red: 0.1, green: 0.1, blue: 0.1, opacity: 1),
        candidateCodeColor: ColorData(red: 0.3, green: 0.3, blue: 0.3, opacity: 0.8),
        candidateBackgroundColor: defaultLightBackgroundColor.withOpacity(opacity: 0),
        tooltipBackgroundColor: defaultLightGreyColor,
        tooltipSelectedTextColor: defaultLightAccentColor.withOpacity(opacity: 0.8),
        selectedIndexColor: defaultLightAccentColor,
        selectedTextColor: defaultLightBackgroundColor,
        selectedCodeColor: defaultLightAccentColor.withOpacity(opacity: 0.8),
        selectedBackgroundColor: defaultLightAccentColor,
        pageIndicatorColor: defaultLightAccentColor,
        pageIndicatorDisabledColor: defaultLightAccentColor.withOpacity(opacity: 0.4),
        fontName: "system",
        fontSize: 20,
        annotationFontSize: 14
    ),
    dark: ApperanceThemeConfig(
        windowBackgroundColor: defaultDarkBackgroundColor,
        windowPaddingTop: 6,
        windowPaddingLeft: 10,
        windowPaddingRight: 10,
        windowPaddingBottom: 6,
        windowBorderRadius: 6,
        originCodeColor: ColorData(red: 1, green: 1, blue: 1, opacity: 1),
        originCandidatesSpace: 6,
        candidateSpace: 8,
        candidateIndexColor: ColorData(red: 0.6, green: 0.6, blue: 0.6, opacity: 1),
        candidateTextColor: ColorData(red: 0.9, green: 0.9, blue: 0.9, opacity: 1),
        candidateCodeColor: ColorData(red: 0.7, green: 0.7, blue: 0.7, opacity: 0.8),
        candidateBackgroundColor: defaultDarkBackgroundColor,
        tooltipBackgroundColor: defaultDarkGreyColor,
        tooltipSelectedTextColor: defaultDarkAccentColor.withOpacity(opacity: 0.8),
        selectedIndexColor: defaultDarkAccentColor,
        selectedTextColor: defaultDarkBackgroundColor,
        selectedCodeColor: defaultDarkAccentColor.withOpacity(opacity: 0.8),
        selectedBackgroundColor: defaultDarkAccentColor,
        pageIndicatorColor: defaultDarkAccentColor,
        pageIndicatorDisabledColor: defaultDarkAccentColor.withOpacity(opacity: 0.4),
        fontName: "system",
        fontSize: 20,
        annotationFontSize: 14
    )
)

func loadThemeConfig(jsonData: String) -> ThemeConfig? {
    let decoder = JSONDecoder()
    do {
        return try decoder.decode(ThemeConfig.self, from: jsonData.data(using: .utf8)!)
    } catch {
        print(error)
        return nil
    }
}

func jsonThemeConfig(config: ThemeConfig) -> String? {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(config) {
        return String(data: data, encoding: .utf8)!
    }
    return nil
}
