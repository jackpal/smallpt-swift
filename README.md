# Small Path Tracer in Swift

This is a straightforward translation of http://www.kevinbeason.com/smallpt/
to Swift.

# Example Image

![An example output image](image.jpg)

# Setup

+ Install Xcode 6.1
+ Install a PPM image viewing program such as
  [Toy Viewer](https://itunes.apple.com/us/app/toyviewer/id414298354?mt=12)

# Build and run

    xcrun swiftc -O -sdk `xcrun --show-sdk-path --sdk macosx` smallpt.swift
    ./smallpt
    open image.ppm

You can also run the swift file directly. And in either case you can
supply the number of samples per pixel. (Default = 4 samples per pixel.):

    ./smallpt.swift 512 && open image.ppm

# Performance

On a MacBook Pro (Retina, 15-inch, Early 2013):

Language              | time (seconds)
----------------------|---------------------------------------------------
C++ single threaded   | 5.6 s
Swift single threaded | 13.8 s (of which 5.6 s is rendering, 8 s is file output)
Swift GCD             | 9.8 s (of which 1 s is rendering, 8 s is file output)

## Discussion

 - Swift file output seems to be very slow compared to C.
    - partly because it is unbuffered
    - partly because it is converting from Unicode to UTF8
