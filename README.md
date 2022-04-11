# CardCarousel

Card carousel is an elegant SwiftUI slider compatible with Swift Package Manager

Loopping             |  Not looping
:-------------------------:|:-------------------------:
![carousel-loop](https://user-images.githubusercontent.com/12393850/162489306-9bfb65cc-e4f3-4a33-b00e-31fc33365bab.gif)  |  ![carousel-no-loop](https://user-images.githubusercontent.com/12393850/162490085-1acd1a64-5c55-4831-902b-fa904b907bc3.gif)

## Setup

### 1. Import the library
```kotlin

import CardCarousel
```

### 2. Use the SwiftUI component

```kotlin
Carousel(items, id: \.self, isLooping: true, content: { item in
  Card(item: item)
})
```

## Parameters

- index : Binding data to set active item
- sidesScaling: Size of previous and next card 
- isLooping: Allow carousel to loop
- canMove: Allow swiping
