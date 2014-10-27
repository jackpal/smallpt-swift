Small Path Tracer in Swift

This is a straightforward translation of http://www.kevinbeason.com/smallpt/
to Swift.

Example Image

![An example output image](image.jpg)

Setup

+ Install Xcode 6.1
+ Install a PPM image viewing program such as https://itunes.apple.com/us/app/toyviewer/id414298354?mt=12

Build and run

    xcrun swiftc -O -sdk `xcrun --show-sdk-path --sdk macosx` smallpt.swift
    ./smallpt
    open image.ppm

You can also supply the number of samples per pixel:

    ./smallpt.swift 512 && open image.ppm

Remarks

On a MacBook Pro (Retina, 15-inch, Early 2013):

Language              | time (seconds)
----------------------|-------------
C++ single threaded   |  5.6s
Swift single threaded | 13.8s (Of which 5.6s is rendering, 8s file i/o)
Swift GCD             |  9.8s (Of which 1s is rendering, 8s file i/o)

Bugs:

 - Swift File I/O seems to be slow.
