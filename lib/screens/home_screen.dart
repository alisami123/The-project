import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medication_provider.dart';
import '../utils/app_theme.dart';
import 'add_medication_screen.dart';

/// Main home screen displaying all medications and upcoming reminders.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the provider on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedicationProvider>(context, listen: false).initialize();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<MedicationProvider>(context, listen: false)
                  .initialize();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _MedicationsList(),
          _RemindersView(),
          _SettingsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMedicationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
            )
          : null,
    );
  }
}

/// Displays the list of all medications.
class _MedicationsList extends StatelessWidget {
  const _MedicationsList();

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: const TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.clearError();
                    provider.initialize();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final medications = provider.medications;

        if (medications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 80,
                  color: AppTheme.lightBrown,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No medications yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the + button to add your first medication',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => provider.initialize(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return _MedicationCard(medication: medication);
            },
          ),
        );
      },
    );
  }
}

/// Card widget for displaying a single medication.
class _MedicationCard extends StatelessWidget {
  final dynamic medication;

  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMedicationScreen(medication: medication),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Medication image or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: medication.imageUrl != null
                    ? Image.file(
                        File(medication.imageUrl!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 16),
              // Medication details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            medication.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: medication.isActive
                                ? AppTheme.successGreen.withOpacity(0.2)
                                : AppTheme.lightBrown.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            medication.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: medication.isActive
                                  ? AppTheme.successGreen
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medication.pillCount} pill(s) • ${_frequencyText(medication.frequency)} daily',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Schedule times
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: medication.scheduleElements.map((element) {
                        final timeStr =
                            '${element.hour.toString().padLeft(2, '0')}:${element.minute.toString().padLeft(2, '0')}';
                        return Chip(
                          label: Text(
                            element.label ?? timeStr,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: element.isTaken
                              ? AppTheme.successGreen.withOpacity(0.2)
                              : AppTheme.lightBrown,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.veryLightBrown,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.medication,
        size: 40,
        color: AppTheme.lightBrown,
      ),
    );
  }

  String _frequencyText(int frequency) {
    switch (frequency) {
      case 1:
        return 'Once';
      case 2:
        return 'Twice';
      case 3:
        return 'Three times';
      default:
        return '$frequency times';
    }
  }
}

/// Displays upcoming reminders for today.
class _RemindersView extends StatelessWidget {
  const _RemindersView();

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, provider, child) {
        final reminders = provider.getUpcomingReminders();

        if (reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: AppTheme.lightBrown,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No upcoming reminders',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All doses taken or no medications scheduled',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            final med = reminder['medication'] as dynamic;
            final element = reminder['scheduleElement'] as dynamic;
            final scheduleIndex = reminder['scheduleIndex'] as int;

            final timeStr =
                '${element.hour.toString().padLeft(2, '0')}:${element.minute.toString().padLeft(2, '0')}';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBrown,
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(med.title),
                subtitle: Text(
                    '${med.pillCount} pill(s)${element.label != null ? ' • ${element.label}' : ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppTheme.successGreen,
                  onPressed: () {
                    provider.markDoseAsTaken(med.id, scheduleIndex);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Marked ${med.title} as taken'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Settings and app information view.
class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        _SettingsTile(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'Version 1.0.0',
        ),
        _SettingsTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('How to Use'),
                content: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('1. Tap the + button to add a medication'),
                      const SizedBox(height: 8),
                      const Text('2. Take a photo of your medication'),
                      const SizedBox(height: 8),
                      const Text('3. Set the number of pills and frequency'),
                      const SizedBox(height: 8),
                      const Text('4. Choose reminder times'),
                      const SizedBox(height: 8),
                      const Text('5. Tap on a medication to edit or delete it'),
                      const SizedBox(height: 8),
                      const Text('6. Mark doses as taken in the Reminders tab'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 32),
        _SettingsTile(
          icon: Icons.delete_sweep,
          title: 'Clear All Data',
          subtitle: 'Warning: This will delete all medications',
          isDestructive: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear All Data?'),
                content: const Text(
                  'This will permanently delete all medications and their data. This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Delete All'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppTheme.errorRed : AppTheme.primaryBrown,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppTheme.errorRed : AppTheme.textPrimary,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
