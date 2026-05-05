# Windows Setup Requirements

This is the simplest setup for running the app on a clean Windows laptop with VS Code.
Android Studio is not required.
VS Code and the Flutter extension are assumed to already be installed.
Git is not required to run the app from the shared zip.

## Install once

1. Install JDK 17.
2. Download the latest Flutter SDK Windows stable zip from the Flutter SDK archive, extract it to `C:\src\flutter`, and add `C:\src\flutter\bin` to PATH. The bundled Dart SDK is compatible with the project's `sdk: ^3.10.7` constraint.
3. Install the Android command-line tools.
4. Add these folders to PATH:
	- `C:\src\flutter\bin`
	- `C:\Android\cmdline-tools\latest\bin`
	- `C:\Android\Sdk\platform-tools`
5. Install the Android SDK packages with:

```cmd
sdkmanager --sdk_root=C:\Android\Sdk "platform-tools" "platforms;android-35" "build-tools;35.0.0"
```

6. Accept the Android licenses:

```cmd
flutter doctor --android-licenses
```

## Run the app in VS Code

Open the project folder in VS Code, open the VS Code terminal, and run:

```cmd
flutter pub get
flutter run
```

`flutter run` will start the app on a connected Android phone or on a running emulator.

## If something is missing

Run this once to see what Flutter still needs:

```cmd
flutter doctor
```

If you also want the Python scripts in `training/`, install the packages from `training/requirements.txt` separately.