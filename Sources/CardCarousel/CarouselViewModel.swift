//
//  CarouselViewModel.swift
//  
//
//  Created by Pierre-Antoine Fagniez on 08/04/2022.
//

import Combine
import SwiftUI

@available(macOS 10.15, *)
@available(iOS 13.0, *)
class CarouselViewModel<Data, ID>: ObservableObject where Data: RandomAccessCollection, ID: Hashable, Data.Element: Equatable {
    /// external index
    @Binding private var index: Int

    private let _data: Data
    private let _dataId: KeyPath<Data.Element, ID>
    private let _isLooping: Bool
    private let _sidesScaling: CGFloat
    private let _canMove: Bool

    init(_ data: Data, id: KeyPath<Data.Element, ID>, index: Binding<Int>, sidesScaling: CGFloat, isLooping: Bool, canMove: Bool) {
        guard index.wrappedValue < data.count else {
            fatalError("The index should be less than the count of data ")
        }

        _data = data
        _dataId = id
        _isLooping = isLooping
        _sidesScaling = sidesScaling
        _canMove = canMove
        activeIndex = index.wrappedValue
        _index = index
    }

    /// The index of the currently active subview.
    @Published var activeIndex: Int = 0 {
        willSet {
            index = newValue
        }
        didSet {
            isAnimatedOffset = true
        }
    }

    /// Offset x of the view drag.
    @Published var dragOffset: CGFloat = .zero

    /// size of GeometryProxy
    var viewSize: CGSize = .zero
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension CarouselViewModel where ID == Data.Element.ID, Data.Element: Identifiable {
    convenience init(_ data: Data, index: Binding<Int>, sidesScaling: CGFloat, isLooping: Bool, canMove: Bool) {
        self.init(data, id: \.id, index: index, sidesScaling: sidesScaling, isLooping: isLooping, canMove: canMove)
    }
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension CarouselViewModel {
    var data: Data {
        return _data
    }

    var dataId: KeyPath<Data.Element, ID> {
        return _dataId
    }

    var offsetAnimation: Animation? {
        guard isLooping else {
            return .spring()
        }
        return isAnimatedOffset ? .spring() : .none
    }

    var itemWidth: CGFloat {
        max(0, viewSize.width)
    }

    // swiftlint:disable force_cast
    private var activeItem: Data.Element? {
        guard activeIndex < data.count else {
            return nil
        }
        return data[activeIndex as! Data.Index]
    }

    private var previousItem: Data.Element? {
        if activeIndex == 0 {
            if isLooping {
                return data.last
            } else {
                return nil
            }
        } else {
            let previousIndex = max(activeIndex - 1, 0)
            return data[previousIndex as! Data.Index]
        }
    }

    private var nextItem: Data.Element? {
        if activeIndex == data.count - 1 {
            if isLooping {
                return data.first
            } else {
                return nil
            }
        } else {
            let nextIndex = min(activeIndex + 1, data.count - 1)
            return data[nextIndex as! Data.Index]
        }
    }

    // swiftlint:enable force_cast

    func isActiveItem(_ item: Data.Element) -> Bool {
        return activeItem?[keyPath: _dataId] == item[keyPath: _dataId]
    }

    func isNextItem(_ item: Data.Element) -> Bool {
        return item == nextItem
    }

    func isPreviousItem(_ item: Data.Element) -> Bool {
        return item == previousItem
    }

    /// Defines the scaling based on whether the item is currently active or not.
    /// - Parameter item: The incoming item
    /// - Returns: scaling
    func itemScaling(_ item: Data.Element) -> CGFloat {
        guard activeItem != nil else {
            return 0
        }
        return isActiveItem(item) ? 1 : sidesScaling
    }
    
    func itemOpacity(_ item: Data.Element) -> CGFloat {
        return isActiveItem(item) || isPreviousItem(item) || isNextItem(item) ? 1 : 0
    }

    /// Defines the scaling based on whether the item is currently active or not.
    /// - Parameter item: The incoming item
    /// - Returns: scaling
    func zIndex(_ item: Data.Element) -> Double {
        if isActiveItem(item) {
            return 1
        } else if isNextItem(item) || isPreviousItem(item) {
            return 0
        } else {
            return -1
        }
    }
}

// MARK: - private variable

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension CarouselViewModel {
    private var isLooping: Bool {
        return _data.count > 1 ? _isLooping : false
    }

    private var sidesScaling: CGFloat {
        return max(min(_sidesScaling, 1), 0)
    }

    /// Is animated when view is in offset
    private var isAnimatedOffset: Bool {
        get { UserDefaults.isAnimatedOffset }
        set { UserDefaults.isAnimatedOffset = newValue }
    }
}

// MARK: - Offset Method

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension CarouselViewModel {
    /// current offset value
    var offset: CGFloat {
        return dragOffset
    }

    func offset(_ item: Data.Element) -> CGSize {
        if item == previousItem {
            let offset = min(-25, dragOffset)
            return CGSize(width: offset, height: 0)
        } else if item == nextItem {
            let offset = max(dragOffset, 25)
            return CGSize(width: offset, height: 0)
        } else if item == activeItem {
            let isSwipingRight = offset > 0
            let activeItemOffset = isSwipingRight ? min(itemWidth / CGFloat(3), offset) : max(-itemWidth / CGFloat(3), offset)
            return CGSize(width: activeItemOffset, height: 0)
        } else {
            return CGSize(width: 0, height: 0)
        }
    }
}

// MARK: - Drag Gesture

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension CarouselViewModel {
    /// drag gesture of view
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged(dragChanged)
            .onEnded(dragEnded)
    }

    private func dragChanged(_ value: DragGesture.Value) {
        guard _canMove else { return }

        isAnimatedOffset = true

        let dragValue = value.translation.width
        /// Defines the maximum value of the drag
        /// Avoid dragging more than the values of multiple subviews at the end of the drag,
        /// and still only one subview is toggled
//        var offset: CGFloat = 4
//        if dragValue > 0 {
//            offset = min(offset, dragValue / 4)
//        } else {
//            offset = max(-offset, dragValue / 4)
//        }
        /// set drag offset
        dragOffset = dragValue
    }

    private func dragEnded(_ value: DragGesture.Value) {
        guard _canMove else { return }
        /// reset drag offset
        dragOffset = .zero

        /// Defines the drag threshold
        /// At the end of the drag, if the drag value exceeds the drag threshold,
        /// the active view will be toggled
        /// default is one fourth of subview
        let dragThreshold: CGFloat = itemWidth / 5
//
        var activeIndex = self.activeIndex
        if value.translation.width > dragThreshold {
            activeIndex -= 1
        }
        if value.translation.width < -dragThreshold {
            activeIndex += 1
        }
        toggleIndex(newIndex: activeIndex)
    }

    private func toggleIndex(newIndex: Int) {
        if newIndex > _data.count - 1 {
            activeIndex = isLooping ? 0 : newIndex - 1
        } else if newIndex < 0 {
            activeIndex = isLooping ? data.count - 1 : 0
        } else {
            activeIndex = newIndex
        }
    }
}

@available(macOS 10.15, *)
private extension UserDefaults {
    private enum Keys {
        static let isAnimatedOffset = "isAnimatedOffset"
    }

    static var isAnimatedOffset: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.isAnimatedOffset)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.isAnimatedOffset)
        }
    }
}

