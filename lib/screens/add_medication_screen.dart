import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medication_provider.dart';
import '../services/image_service.dart';
import '../utils/app_theme.dart';
import '../models/medication.dart';

/// Screen for adding or editing a medication.
class AddMedicationScreen extends StatefulWidget {
  final Medication? medication;

  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pillCountController = TextEditingController();

  int _frequency = 1;
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  File? _imageFile;
  bool _isLoading = false;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.medication != null) {
      _initializeWithMedication(widget.medication!);
    }
  }

  void _initializeWithMedication(Medication med) {
    _titleController.text = med.title;
    _descriptionController.text = med.description ?? '';
    _pillCountController.text = med.pillCount.toString();
    _frequency = med.frequency;
    _selectedTimes = med.scheduleElements
        .map((e) => TimeOfDay(hour: e.hour, minute: e.minute))
        .toList();
    if (med.imageUrl != null) {
      _imageFile = File(med.imageUrl!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pillCountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImageService().takePhoto();
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _selectTime(int index) async {
    final currentTime = _selectedTimes[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBrown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  void _updateFrequency(int newFrequency) {
    setState(() {
      // Adjust times list to match new frequency
      while (_selectedTimes.length < newFrequency) {
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
      }
      if (_selectedTimes.length > newFrequency) {
        _selectedTimes = _selectedTimes.sublist(0, newFrequency);
      }
      _frequency = newFrequency;
    });
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final scheduleTimes =
        _selectedTimes.map((t) => Duration(hours: t.hour, minutes: t.minute)).toList();

    bool success;
    if (_isEditing) {
      success = await provider.updateMedication(
        id: widget.medication!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        pillCount: int.parse(_pillCountController.text),
        frequency: _frequency,
        scheduleTimes: scheduleTimes,
        newImageFile: _imageFile,
        removeImage: _imageFile == null && widget.medication!.imageUrl != null,
      );
    } else {
      success = await provider.createMedication(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        pillCount: int.parse(_pillCountController.text),
        frequency: _frequency,
        scheduleTimes: scheduleTimes,
        imageFile: _imageFile,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Medication updated' : 'Medication added',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save medication'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'Add Medication'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image capture section
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.veryLightBrown,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightBrown, width: 2),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: AppTheme.lightBrown,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to photograph\nmedication',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Medication name
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Medication Name *',
                prefixIcon: Icon(Icons.medication, color: AppTheme.primaryBrown),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.note, color: AppTheme.primaryBrown),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Pill count
            TextFormField(
              controller: _pillCountController,
              decoration: const InputDecoration(
                labelText: 'Pills per Dose *',
                prefixIcon: Icon(Icons.tablet, color: AppTheme.primaryBrown),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                final count = int.tryParse(value);
                if (count == null || count <= 0) {
                  return 'Must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Frequency selector
            const Text(
              'Daily Frequency *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Once')),
                ButtonSegment(value: 2, label: Text('Twice')),
                ButtonSegment(value: 3, label: Text('3x')),
              ],
              selected: {_frequency},
              onSelectionChanged: (Set<int> selection) {
                _updateFrequency(selection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primaryBrown;
                  }
                  return AppTheme.veryLightBrown;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppTheme.textPrimary;
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Time selectors
            const Text(
              'Reminder Times *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_frequency, (index) {
              final labels = ['Morning', 'Afternoon', 'Evening'];
              final time = _selectedTimes[index];
              final displayTime = time.format(context);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.lightBrown),
                  ),
                  tileColor: AppTheme.veryLightBrown,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBrown,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(_frequency > 1 ? labels[index] : 'Reminder Time'),
                  subtitle: Text(displayTime),
                  trailing: IconButton(
                    icon: const Icon(Icons.access_time),
                    color: AppTheme.primaryBrown,
                    onPressed: () => _selectTime(index),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveMedication,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Update Medication' : 'Save Medication'),
            ),
            const SizedBox(height: 16),

            // Delete button (only when editing)
            if (_isEditing)
              OutlinedButton(
                onPressed: () => _confirmDelete(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                ),
                child: const Text('Delete Medication'),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication?'),
        content: Text(
            'Are you sure you want to delete "${widget.medication!.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<MedicationProvider>(context, listen: false);
              final success = await provider.deleteMedication(widget.medication!.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medication deleted'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
