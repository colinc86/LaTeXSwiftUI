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

### Modifiers

The `LaTeX` view's body is built up of `Text` views so feel free to use any of the supported modifiers.

```swift
LaTeX("Hello, $\\LaTeX$!")
  .fontDesign(.serif)
  .foregroundColor(.blue)
```

### Parsing Mode

Text input can either be completely rendered, or `LaTeXSwiftUI` can search for top-level equations. The default behavior is to only render equations. Use the `parsingMode` to change the default behavior.

```swift
LaTeX("e^{i\\pi}+1=0", parsingMode: .all)
```

### Rendering Mode

You can specify the rendering mode of the rendered equations so that they either take on the style of the surrounding text, or display the style rendered by MathJax.

```swift
LaTeX("Hello, $\\color{red}\\LaTeX$!", renderingMode: .original)
  .fontDesign(.serif)
  .foregroundColor(.blue)
```

### TeX Options

For more control over the MathJax rendering, you can pass a `TeXInputProcessorOptions` object to the view.

```swift
let options = TeXInputProcessorOptions(tags: .ams)
LaTeX("""
\\begin{equation}
  e^{i\\pi}+1=0
\\end{equation}
""", options: options)
```
