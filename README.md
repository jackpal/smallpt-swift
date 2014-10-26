Small Path Tracer in Swift

This is a straightforward translation of http://www.kevinbeason.com/smallpt/
to Swift.

Setup

+ Install Xcode 6.1
+ Install a PPM image viewing program such as https://itunes.apple.com/us/app/toyviewer/id414298354?mt=12

Build and run

    ./smallpt.swift && open image.ppm

You can also supply the number of samples per pixel:

    ./smallpt.swift 512 && open image.ppm

Remarks

Swift does not seem to be particularly suited to running this application.

On a MacBook Pro (Retina, 15-inch, Early 2013):

Language | time seconds
---------|-------------
C |
Swift |

