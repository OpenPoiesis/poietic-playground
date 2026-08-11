# Poietic Playground

**IMPORTANT:** This is just an unstable and experimental prototype.

**IMPORTANT:** If you want to contribute, please read below.

An educational tool, a virtual laboratory for modelling and simulation of
dynamical systems using the [Stock and Flow](https://en.wikipedia.org/wiki/Stock_and_flow)
methodology.

Part of the [Open Poiesis](https://www.poietic.org) project.

## Primers

The following literature is a good start with the methodology used in the playground:

- [Thinking In Systems: A Primer](https://www.goodreads.com/book/show/3828902-thinking-in-systems) by Donella Meadows
- [Business Dynamics: Systems Thinking and Modeling for a Complex World](https://www.goodreads.com/book/show/808680.Business_Dynamics?ref=nav_sb_ss_1_36) by John D. Sterman

## Prerequisites

Uses Swift programming language and requires SDL3 library.

- On MacOS: `brew install sdl3`
- On Linux: `apt-get install libsdl3-dev`

See SDL [installation instructions](https://github.com/libsdl-org/SDL/blob/main/INSTALL.md) for more details.

Install Swift:

- On MacOS: [Install Xcode](https://developer.apple.com/xcode/).
- On other platforms: [Install Swift](https://www.swift.org/getting-started/)

## Build and Run

To build and run the application: `swift run`.

## See Also

- [Poietic Core](https://github.com/OpenPoiesis/poietic-core) – Model and design representation library
- [Poietic Flows](https://github.com/OpenPoiesis/poietic-flows) – Stock and Flow simulation library

## Contributing

_All humans are more than welcome to contribute to the project._

**Contributions that are substantially generative AI/LLM-generated (such as code or issues)**,
without substantive human authorship, verification and understanding, will be rejected
without further review, regardless of content.


**Generative AI/LLM-assisted human contribution might be allowed** with prior discussion
and disclosure. The disclosure must confirm that:


- You fully understand every part of the contribution, and can answer questions about it
  without using AI assistance.
- You have personally tested and verified it.
- You clearly indicate which parts of the content is AI generated.

The human contributor takes full responsibility for all code, including its correctness
and licensing compliance.

## Authors

- [Stefan Urbanek](mailto:stefan.urbanek@gmail.com)

## Credits

This package includes code from the following libraries:

- [ImGui](https://github.com/ocornut/imgui)
- [ImGuiFD](https://github.com/Julianiolo/ImGuiFD)
- [stb](https://github.com/nothings/stb)
- [SDL3](https://libsdl.org)
