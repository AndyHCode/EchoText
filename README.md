# EchoText - Offline Text-to-Speech iOS App

## About The Project

An iOS application that delivers high-quality, transformer-based text-to-speech (TTS) capabilities entirely on-device. This app provides a cost-effective, privacy-focused alternative to cloud-based TTS services.

### Built With
* [![Swift v6.0][Swift-v]](https://www.swift.org/)
* [![SwiftUI v6.0][SwiftUI-v]](https://developer.apple.com/xcode/swiftui/)
* [![SQLite v3.46.1][SQLite-v]](https://www.sqlite.org/index.html)
* [![Sherpa-ONNX v1.10.27][Sherpa-v]](https://github.com/k2-fsa/sherpa-onnx)

## Getting Started

### Prerequisite for building
* macOS device running Xcode 16.0

### Prerequisite for Deployment
* an iPhone running iOS 17.0 or later

### Installation

1. Clone the repository
   ```sh
   git clone https://github.com/Harsh-59/AI-Voices
   ```
2. Navigate into AI-Voices/Dependencies/
3. unzip build-ios.zip
4. move the "build-ios" folder that has "ios-onnxruntime" and "sherpa-onnx.xcframework" into AI-Voices/sherpa-onnx/
5. Navigate into AI-Voices/sherpa-onnx/ios-swiftui/
6. Open "SherpaOnnxTts.xcodeproj" project in Xcode
7. select the target device on the top center of Xcode
8. Build and run on the target device using Xcode by pressing the play icon on the top right

Note: To build on a physical IOS device, you will need to connect the iPhone to a Mac, have a free or paid Apple developer account, and have developer mode enabled on the iPhone which is in the settings app. You will then need to sign the app by clicking on the SherpaOnnxTts on the top left in the file tree view, clicking on "Signing & Capabilities", selecting team (which is your Apple account), and creating a "Bundle Identifier" (ex: com.Andy.SherpaOnnxTts).
## Preview

<img src="Documents/images/EchoText image 1.png" align="left" width="300">
<img src="Documents/images/EchoText image 2.png" align="left" width="300">
<img src="Documents/images/EchoText image 3.png" align="auto" width="300">

## Features
- **Offline Text-to-Speech Conversion**
  - Utilizes Sherpa-ONNX for local processing
  - No internet connection is required
  - Privacy-focused design
- **Support for multiple text input methods:**
  - Direct text input
  - PDF document import
- **Voice customization:**
  - Adjustable speed and pitch
  - Custom voice profiles
  - Model selection
- **Audio management:**
  - Audio file organization
  - Playback controls + Queue player system
  - Share Functionality
- **Document management:**
  - Document file organization
  - Document batch conversion
  - Document page selection for conversion
- **Security features:**
  - Optional passcode protection
  - Recovery code system
  - Local data encryption

  NOTE: Refer to the ***User Manual*** for more details about the functionality of the app

## Team
* **[Kevin Xing](https://github.com/yosunkx)**
* **[Ahmad Ghaddar](https://github.com/NoshGiven)**
* **[Andy Huang](https://github.com/AndyHCode)**
* **[Harsh Bhagat](https://github.com/Harsh-59)**

<!-- MARKDOWN LINKS & IMAGES -->
[Swift-v]: https://img.shields.io/badge/Swift_6.0-FA7343?style=for-the-badge&logo=swift&logoColor=white
[SwiftUI-v]: https://img.shields.io/badge/SwiftUI_6.0-blue?style=for-the-badge&logo=swift&logoColor=white
[SQLite-v]: https://img.shields.io/badge/SQLite_3.46.1-07405E?style=for-the-badge&logo=sqlite&logoColor=white
[Sherpa-v]: https://img.shields.io/badge/Sherpa--ONNX_1.10.27-FF6B6B?style=for-the-badge
