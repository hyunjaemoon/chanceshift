# ChanceShift
Arcade Game with Randomness Chaos

![ChanceShift Logo](demo/chanceshift_title.gif)

# How to Build

## Prerequisites
Before you start, ensure you have the following installed on your system:
- Git
- Flutter SDK
- An IDE (such as Android Studio, VS Code, etc.)
- An emulator or a physical device to run the app

## Step 1: Clone the Repository
Open a terminal and run the following command to clone the GitHub repository:

    git clone https://github.com/hyunjaemoon/chanceshift.git

## Step 2: Navigate to the Project Directory
Change the directory to the project folder by executing:

    cd chanceshift

## Step 3: Install Dependencies
In the project directory, run the following command to fetch and install all the necessary dependencies:

    flutter pub get

## Step 4: Open the Project in Your IDE
Open your preferred IDE and select 'Open an Existing Project', then navigate to the project directory you have cloned.

## Step 5: Run the App
- **Using the Command Line:**
  You can run the app using the following command:

      flutter run

  If you have multiple devices connected, use the `-d` flag to specify the device:

      flutter run -d device_id

  Replace `device_id` with the ID of the device or emulator you want to use. You can list all connected devices with `flutter devices`.

- **Using Your IDE:**
  Most IDEs have a 'Run' button that can be used to launch your application. Ensure that the correct device is selected in the device toolbar.

## Step 6: Build and Generate APK/IPA (Optional)
If you want to build a release version of your app, you can generate an APK for Android or an IPA for iOS by running:

- **For Android:**

      flutter build apk

- **For iOS:**

      flutter build ios

Note: For iOS, you may need to configure signing capabilities in Xcode before building the project.

## Step 7: Troubleshooting
If you encounter any issues during the setup or while running the app, consult the Flutter documentation or search for the error message online. Common issues usually involve missing SDK paths or dependency conflicts.

This guide assumes you are familiar with basic terminal commands and the general software development lifecycle. If you are new to Flutter or development in general, consider exploring additional resources or tutorials specific to these areas.

# Author
Hyun Jae Moon [calhyunjaemoon@gmail.com]
