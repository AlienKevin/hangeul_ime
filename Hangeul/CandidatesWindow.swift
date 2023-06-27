//
//  CandidatesWindow.swift
//  Hangeul
//
//  Created by Kevin Li on 10/23/22.
//  src: https://github.com/qwertyyb/Fire/blob/master/Fire/CandidatesWindow.swift

import SwiftUI
import InputMethodKit

typealias CandidatesData = (list: [Candidate], hasPrev: Bool, hasNext: Bool, selectedIndex: Int)

class CandidatesWindow: NSWindow, NSWindowDelegate {
    let hostingView = NSHostingView(rootView: CandidatesView(candidates: [], origin: ""))
    let tooltipView = NSHostingView(rootView: AnyView(EmptyView()))

    func windowDidMove(_ notification: Notification) {
        /* windowDidMove会先于windowDidResize调用，所以需要
         * 在DispatchQueue.main.async中调用，以便能拿到最新的窗口大小
         **/
        DispatchQueue.main.async {
            self.limitFrameInScreen()
        }
    }

    func windowDidResize(_ notification: Notification) {
        /* 窗口大小变化时，确保不会超出当前屏幕范围，
         * 但是输入第一个字符时，也即窗口初次显示时，不会触发此事件, 所以需要配合windowDidMove方法一起使用
         */
        limitFrameInScreen()
    }

    func setCandidates(
        _ candidatesData: CandidatesData,
        originalString: String,
        topLeft: NSPoint
    ) {
        hostingView.rootView.candidates = candidatesData.list
        hostingView.rootView.origin = originalString
        hostingView.rootView.hasNext = candidatesData.hasNext
        hostingView.rootView.hasPrev = candidatesData.hasPrev
        hostingView.rootView.selectedIndex = candidatesData.selectedIndex
        
        createTooltipView()
        
        print("origin top left: \(topLeft)")
        print("candidates: \(candidatesData)")
        self.setFrameTopLeftPoint(topLeft)
        self.orderFront(nil)
//        NSApp.setActivationPolicy(.prohibited)
    }
    
    func createTooltipView() {
        // Add tooltipView to contentView if it is not there already
        if tooltipView.superview == nil {
            self.contentView?.addSubview(tooltipView)
        }
        
        // Clear any previous constraints on tooltipView
        tooltipView.removeConstraints(tooltipView.constraints)
        
        // Create constraints
        let xOffset: CGFloat = 20
        let yOffset: CGFloat = 0
        
        let horizontalConstraint = NSLayoutConstraint(
            item: tooltipView,
            attribute: .leading,
            relatedBy: .equal,
            toItem: hostingView,
            attribute: .trailing,
            multiplier: 1,
            constant: xOffset)
        
        let verticalConstraint = NSLayoutConstraint(
            item: tooltipView,
            attribute: .top,
            relatedBy: .equal,
            toItem: hostingView,
            attribute: .top,
            multiplier: 1,
            constant: yOffset)
        
        NSLayoutConstraint.activate([horizontalConstraint, verticalConstraint])
        
        let selectedCandidate = hostingView.rootView.candidates[hostingView.rootView.selectedIndex]
        
        let (derivedPr, explanations) = g2p(word: selectedCandidate.koreanWord)
        
        if selectedCandidate.prs.contains(derivedPr) && !explanations.isEmpty {
            self.tooltipView.isHidden = false
            tooltipView.rootView = AnyView(PointingTooltipView(
                text: explanations.map { $0.result + ":\t" + $0.pattern + "\t→\t" + $0.template }.joined(separator: "\n"),
                tooltipDirection: .right
            ))
        } else {
            self.tooltipView.isHidden = true
        }
    }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        level = NSWindow.Level(rawValue: NSWindow.Level.RawValue(CGShieldingWindowLevel()))
        styleMask = .init(arrayLiteral: .fullSizeContentView, .borderless)
        isReleasedWhenClosed = false
        backgroundColor = NSColor.clear
        delegate = self
        setSizePolicy()
    }

    private func limitFrameInScreen() {
       let origin = self.transformTopLeft(originalTopLeft: NSPoint(x: self.frame.minX, y: self.frame.maxY))
       self.setFrameTopLeftPoint(origin)
    }

    private func setSizePolicy() {
        // 窗口大小可根据内容变化
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        tooltipView.translatesAutoresizingMaskIntoConstraints = false
        
        guard self.contentView != nil else {
            return
        }
        
        self.contentView?.addSubview(hostingView)
        self.contentView?.leftAnchor.constraint(equalTo: hostingView.leftAnchor).isActive = true
//        self.contentView?.rightAnchor.constraint(greaterThanOrEqualTo: hostingView.rightAnchor).isActive = true
        self.contentView?.topAnchor.constraint(equalTo: hostingView.topAnchor).isActive = true
        self.contentView?.bottomAnchor.constraint(equalTo: hostingView.bottomAnchor).isActive = true
        
        self.contentView?.addSubview(tooltipView)
//        self.contentView?.leftAnchor.constraint(lessThanOrEqualTo: tooltipView.leftAnchor).isActive = true
        self.contentView?.rightAnchor.constraint(equalTo: tooltipView.rightAnchor).isActive = true
//        self.contentView?.topAnchor.constraint(lessThanOrEqualTo: tooltipView.topAnchor).isActive = true
//        self.contentView?.bottomAnchor.constraint(greaterThanOrEqualTo: tooltipView.bottomAnchor).isActive = true
    }

    private func transformTopLeft(originalTopLeft: NSPoint) -> NSPoint {
        NSLog("[CandidatesWindow] transformTopLeft: \(frame)")

        let screenPadding: CGFloat = 6

        var left = originalTopLeft.x
        var top = originalTopLeft.y
        if let curScreen = getScreenFromPoint(originalTopLeft) {
            let screen = curScreen.frame

            if originalTopLeft.x + frame.width > screen.maxX - screenPadding {
                left = screen.maxX - frame.width - screenPadding
            }
            if originalTopLeft.y - frame.height < screen.minY + screenPadding {
                top = screen.minY + frame.height + screenPadding
            }
        }
        return NSPoint(x: left, y: top)
    }

    static let shared = CandidatesWindow()
}

func getScreenFromPoint(_ point: NSPoint) -> NSScreen? {
    // find current screen
    for screen in NSScreen.screens {
        if screen.frame.contains(point) {
            return screen
        }
    }
    return NSScreen.main
}
