# Building

## First time

    ./Scripts/fetch-resources
    swift build

`fetch-resources` installs the resources, such as fonts into application's target `Resources`.
Run it once after cloning. Once the resources are in place, running `swift build` is enough.

To fetch resources from a local path:

    ./Scripts/fetch-resources --path ../poietic-assets

## Assets

Fonts and other shared, third-party content live in the
[poietic-assets](https://github.com/openpoiesis/poietic-assets) repository.

See scripts and documentation in the `poietic-assets` repository for more information.
