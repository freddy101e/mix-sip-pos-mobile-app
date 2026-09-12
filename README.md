# Mix & Sip POS

## Running the app on this Windows machine

Open a **new PowerShell window** after the Flutter PATH update. Normal Flutter
commands such as `flutter run` will then work. From an already-open terminal,
use the project wrapper instead:

```powershell
.\flutterw.cmd devices
```

Plain `flutter run` now uses the hosted production API. Use the emulator
launcher only when you intentionally want the local WAMP/Laravel database:

```powershell
# Android emulator: local WAMP/Laravel and local database
.\run-emulator.cmd

# Physical phone: hosted HTTPS Laravel API
.\run-phone.cmd <device-id>

# Physical phone (production is also the default)
flutter run -d <device-id>
```

The hosted Flutter API base is `https://mix-and-sip.devlynq.com/api/v1`.
The app appends `/auth/login`; the browser page `/login` is not an API base.

Run `.\flutterw.cmd devices` to find the physical phone's device ID.

## Receipt printer

The POS prints directly to the Vretti P501A 58mm Bluetooth ESC/POS printer;
the separate Mix & Sip Print companion app is no longer required.

1. Pair the printer from Android **Settings > Bluetooth**.
2. Open POS **Settings > Printing** and allow the Nearby devices permission.
3. Select the paired printer and print a test receipt.
4. Completed POS sales print automatically using receipt lines generated from
   the saved Laravel order.
5. Existing receipts can be printed again from **Orders**, by opening an order
   and selecting **Print receipt**.

The selected Bluetooth address is stored locally on the Android device. A sale
remains completed if printing fails; the POS displays the printer error so the
cashier can correct the connection without submitting the sale again.

## Original template notes

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
