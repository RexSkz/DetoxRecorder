# Contributing

This project is a fork of the original [wix-incubator/DetoxRecorder](https://github.com/wix-incubator/DetoxRecorder), which hasn't been maintained for years. We are actively working on improving the project and adding new features.

## Project Structure

The project is divided into several parts:

- `DetoxRecorder`: an Xcode project that contains the main app.
- `Distribution`: contains the build results to ship.
- `Documentation`: contains the user-facing documentation for the project.
- `TesterApp`/`TesterAppRN`: both are Xcode projects containing the app (native/RN) for testing.

## Getting Started

### Prerequisites

- MacOS & Xcode: the latest version is recommended.
- Node.js: v20 or later.
- pnpm: v9 or later.

It's encouraged to use nvm and Corepack to setup the Node.js environment, please see [the official download page for Node.js](https://nodejs.org/en/download).

### Start The Project

1. Clone the repository.
2. If you want to use native iOS app to debug the recorder:
   1. Open the `DetoxRecorder/TesterApp.xcodeproj` in Xcode.
   2. Directly run the app in Xcode. You will see the app and the recorder toolbar on the simulator.
3. If you want to use React Native app to debug the recorder:
   1. Install the dependencies and run the expo server provided by react native:
      ```shell
      cd TesterAppRN
      pnpm i
      pnpm start
      ```
   2. Open the `DetoxRecorder/TesterAppRN.xcodeproj` in Xcode.
   4. Run the app in Xcode. You will see the app and the recorder toolbar on the simulator.

### Development Guide

There is nothing interesting in the `TesterApp`/`TesterAppRN` projects, they are just the apps for testing the recorder. The main project is `DetoxRecorder`.

There are 3 entities that work together to make the recorder run:

- `EventCapture`: placed in the `EventCapture` folder, uses swizzling to record the user's interactions and generate the commands.
- `Recorder`: placed in the `DetoxRecorder` folder, uses framework injection to attach to the running app, (as a client) send the recorded commands to the server.
- `CLI`: placed in the `DetoxRecorderCLI` folder, the command-line tool that starts the simulator, runs the app with startup flags, (as a server) receives the recorded commands from the recorder.

Here are the main flow:

1. User starts the `CLI`.
2. `CLI` starts the simulator and the app.
3. `Recorder` attaches to the app and starts recording.
4. User interacts with the app.
5. `EventCapture` captures the events and use `Recorder` to send them to the `CLI`.
6. `CLI` receives the events and saves them to a file.

### Build

To build the project, you can use the following commands. If there is no error, you will find the artifact `Distribution/DetoxRecorderCLI`, which is the binary file.

```bash
./build.sh
```

### Run the Binary File

To run the binary file, you can follow these steps:

1. Open the simulator.
2. Run the following command under the root folder:
    ```bash
    ./record.sh \
        --simulatorId booted \
        --bundleId "com.anonymous.TesterAppRN" \        # The bundle ID of the app to record
        --outputTestFile "~/Desktop/RecordedTest.js" \  # The output file path
        --testName "It should record" \                 # The test name
        --record
    ```

### Make Release

// TODO

## Troubleshooting

// TODO
