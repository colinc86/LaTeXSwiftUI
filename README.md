# LaTeXSwiftUI

An easy-to-use SwiftUI view that renders LaTeX.

![iOS Version](https://img.shields.io/badge/iOS-6.1-informational) ![macOS Version](https://img.shields.io/badge/macOS-13-informational)

## Installation

Add the dependency to your package manifest file.

```swift
.package(url: "https://github.com/colinc86/LaTeXSwiftUI", branch: "main")
```

## Usage

Import the package and use the view.

```swift
import LaTeXSwiftUI

struct MyView: View {

  var body: some View {
    LaTeX("Hello, $\\LaTeX$!")
  }

}
```

The `LaTeX` view's body
