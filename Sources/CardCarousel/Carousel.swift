//
//  SwiftUIView.swift
//  
//
//  Created by Pierre-Antoine Fagniez on 08/04/2022.
//

import SwiftUI

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public struct Carousel<Data, ID, Content>: View where Data: RandomAccessCollection, ID: Hashable, Data.Element: Equatable, Content: View {

    @ObservedObject private var viewModel: CarouselViewModel<Data, ID>
    private let content: (Data.Element) -> Content

    public var body: some View {
        GeometryReader { proxy -> AnyView in
            viewModel.viewSize = proxy.size
            return AnyView(generateContent(proxy: proxy))
        }
    }

    private func generateContent(proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            mainContent(proxy: proxy)
            indicators.padding(.top, 32)
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
    }

    private func mainContent(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .center) {
            ForEach(viewModel.data, id: viewModel.dataId) { item in
                content(item)
                    .scaleEffect(x: 1, y: viewModel.itemScaling(item), anchor: .center)
                    .zIndex(viewModel.zIndex(item))
                    .offset(viewModel.offset(item))
                    .opacity(viewModel.itemOpacity(item))
            }
        }
        .gesture(viewModel.dragGesture)
        .animation(viewModel.offsetAnimation, value: viewModel.offset)
    }

    private var indicators: some View {
        HStack(spacing: 7) {
            ForEach(viewModel.data, id: viewModel.dataId) { item in
                let color = Color.black
                let indicatorColor = viewModel.isActiveItem(item) ? color : color.opacity(0.4)
                Circle().fill(indicatorColor)
                    .frame(width: 7, height: 7)
            }
        }
    }
}

// MARK: - Initializers

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension Carousel where Data.Element: Equatable {
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// - Parameters:
    ///   - data: The data that the ``Carousel`` instance uses to create views
    ///     dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - index: The index of currently active.
    ///   - sidesScaling: The scale of the subviews on both sides, limits 0...1,
    ///     default is 0.86.
    ///   - isLooping: Define views to scroll through in a loop, default is false.
    ///   - content: The view builder that creates views dynamically.

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        index: Binding<Int> = .constant(0),
        sidesScaling: CGFloat = 0.86,
        isLooping: Bool = false,
        canMove: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        viewModel = CarouselViewModel(
            data,
            id: id,
            index: index,
            sidesScaling: sidesScaling,
            isLooping: isLooping,
            canMove: canMove
        )
        self.content = content
    }
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension Carousel where ID == Data.Element.ID, Data.Element: Identifiable {
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// - Parameters:
    ///   - data: The identified data that the ``Carousel`` instance uses to
    ///     create views dynamically.
    ///   - index: The index of currently active.
    ///   - sidesScaling: The scale of the subviews on both sides, limits 0...1,
    ///      default is 0.86.
    ///   - isLooping: Define views to scroll through in a loop, default is false.
    ///   - content: The view builder that creates views dynamically.
    public init(
        _ data: Data,
        index: Binding<Int> = .constant(0),
        sidesScaling: CGFloat = 0.86,
        isLooping: Bool = false,
        canMove: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        viewModel = CarouselViewModel(
            data,
            index: index,
            sidesScaling: sidesScaling,
            isLooping: isLooping,
            canMove: canMove
        )
        self.content = content
    }
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
struct Carousel_Previews: PreviewProvider {
    static func content(color: Color) -> some View {
        VStack {
            color
        }
        .frame(width: 267, height: 387)
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }

    static var previews: some View {
        let colors: [Color] = [.blue, .red, .black, .gray, .green]
        Group {
            Carousel(colors, id: \.self, isLooping: true, content: { color in
                content(color: color)
            })
            .frame(height: 430)
            .padding(.horizontal, 20)

            Carousel(colors, id: \.self, isLooping: false, content: { color in
                content(color: color)
            })
            .frame(width: 426)
        }
    }
}

