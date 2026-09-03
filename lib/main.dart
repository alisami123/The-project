import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'providers/medication_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for proper scheduling
  tz.initializeTimeZones();
  
  // Initialize storage service first
  await StorageService().initialize();
  
  runApp(const MedicationReminderApp());
}

/// Main application widget.
/// 
/// Sets up the Provider for state management and applies the app theme.
class MedicationReminderApp extends StatelessWidget {
  const MedicationReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MedicationProvider(),
      child: MaterialApp(
        title: 'Medication Reminder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
