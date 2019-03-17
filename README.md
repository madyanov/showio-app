# Showio

<p>
    <img src="assets/screen-1.png" width="200" />
    <img src="assets/screen-2.png" width="200" />
    <img src="assets/screen-3.png" width="200" />
</p>

[50+ MB Demo GIF](assets/demo.gif)

## Requirements

- iOS 10+
- Swift 4.2
- CocoaPods
- [TMDB API](https://www.themoviedb.org/documentation/api) Key

## Installation

1. Clone this repository and install dependencies:

    ```bash
    $ git clone git@github.com:madyanov/ showio-app.git
    $ cd showio-app
    $ pod install
      ...
    ```

2. Open ShowTracker.xcworkspace in the XCode.

3. Put your TMDB API Key in the Config.plist file.

## Overview

- [Coordinator pattern](http://khanlou.com/2015/10/coordinators-redux/) is used to separate view logic from business logic.
- Core Data is used for local storage.
- Async API provided by the [Promises Toolkit](https://github.com/madyanov/Promises).

## Links

- [AppStore](https://itunes.apple.com/app/id1445035408)
- [Site](https://madyanov.com/showio/)
