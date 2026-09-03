# Medication Reminder App

A production-ready Flutter application for managing medication schedules and delivering reliable local push notifications. Built with CareKit-inspired architecture patterns.

## Features

- **Medication Logging**: Capture medication photos using device camera
- **Flexible Scheduling**: Set 1, 2, or 3 daily reminders with custom times
- **Local Push Notifications**: Timezone-aware notifications with medication photos
- **Data Persistence**: All medications survive app restarts using Hive
- **Clean UI**: Light brown color theme optimized for ease of use
- **Multiple Medications**: Manage unlimited medications with independent schedules

## Architecture

The app follows a clean architecture pattern inspired by Apple's CareKit framework:

### Data Model (CareKit-inspired)

- **Medication**: Similar to CareKit's `OCKTask`, represents a medication with its schedule
- **ScheduleElement**: Similar to `OCKScheduleElement`, defines when medication should be taken
- **Outcome Tracking**: Track whether doses have been taken (`isTaken` property)

### Layer Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models (Medication, ScheduleElement)
├── providers/             # State management (MedicationProvider)
├── screens/               # UI screens (HomeScreen, AddMedicationScreen)
├── services/              # Business logic services
│   ├── storage_service.dart    # Hive database operations
│   ├── notification_service.dart # Local notifications
│   └── image_service.dart      # Camera/gallery access
├── utils/                 # Utilities (AppTheme)
└── widgets/               # Reusable UI components
```

## Getting Started

### Prerequisites

- Flutter SDK 3.5.0 or higher
- Dart SDK 3.5.0 or higher
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd med_reminder
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate Hive adapters (if needed):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

## Platform Configuration

### Android

Required permissions are already configured in `android/app/src/main/AndroidManifest.xml`:

- `CAMERA` - For capturing medication photos
- `POST_NOTIFICATIONS` - For showing reminders (Android 13+)
- `SCHEDULE_EXACT_ALARM` - For precise notification timing
- `RECEIVE_BOOT_COMPLETED` - To restore notifications after reboot
- Storage permissions - For saving medication images

### iOS

Required privacy descriptions are configured in `ios/Runner/Info.plist`:

- `NSCameraUsageDescription` - Camera access for photos
- `NSPhotoLibraryUsageDescription` - Gallery access
- `UIBackgroundModes` - Background notification delivery

## Usage

### Adding a Medication

1. Tap the "+" button on the home screen
2. Take a photo of your medication (or skip)
3. Enter medication name and pill count
4. Select frequency (1, 2, or 3 times daily)
5. Set reminder times for each dose
6. Tap "Save Medication"

### Managing Medications

- **View**: Tap any medication card to view details
- **Edit**: Modify medication details from the edit screen
- **Delete**: Remove medication from the edit screen
- **Toggle Active**: Enable/disable notifications without deleting

### Taking Medication

1. Go to the "Reminders" tab
2. See upcoming doses for today
3. Tap the checkmark to mark as taken

## Technical Details

### Notification Scheduling

Notifications use timezone-aware scheduling via the `timezone` package:

```dart
// Calculate next occurrence at scheduled time
final scheduledDate = tz.TZDateTime(
  tz.local,
  now.year, now.month, now.day,
  scheduleElement.hour,
  scheduleElement.minute,
);

// Schedule with exact timing
await _notifications.zonedSchedule(
  notificationId,
  title,
  body,
  scheduledDate,
  details,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time,
);
```

### Data Persistence

Medications are stored using Hive with type adapters:

```dart
@HiveType(typeId: 0)
class Medication extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(5) List<ScheduleElement> scheduleElements;
  // ... more fields
}
```

### Error Handling

All critical operations include try-catch blocks:

- Notification scheduling failures
- File I/O operations
- Permission denials
- Invalid user inputs

## Testing

Run unit tests:

```bash
flutter test
```

Test coverage includes:
- Medication model creation and serialization
- ScheduleElement time calculations
- Data persistence round-trips

## Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `hive_flutter` | Local database |
| `flutter_local_notifications` | Push notifications |
| `image_picker` | Camera/gallery access |
| `timezone` | Timezone-aware scheduling |
| `permission_handler` | Runtime permissions |

## Color Theme

The app uses a warm light brown color scheme:

- Primary: `#8D6E63` (Warm brown)
- Dark: `#5D4037` (Deep brown)
- Light: `#D7CCC8` (Soft brown)
- Accent: `#A1887F` (Muted brown)
- Success: `#66BB6A` (Green for completed doses)

## Troubleshooting

### Notifications not appearing

1. Check notification permissions in system settings
2. Ensure exact alarm permission is granted (Android)
3. Verify the medication is marked as "Active"
4. Check that reminder times are in the future

### Images not displaying

1. Verify storage permissions are granted
2. Check that the image file exists at the stored path
3. Try re-capturing the medication photo

### Data lost after app restart

1. Ensure Hive initialization completes before accessing data
2. Check that adapters are registered correctly
3. Verify box names match between save and load operations

## License

This project is provided as-is for educational and personal use.

## Contributing

Contributions are welcome! Please ensure:
- Code follows existing patterns
- Tests are included for new features
- Documentation is updated
