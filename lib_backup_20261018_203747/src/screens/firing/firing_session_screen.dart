import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/storage_manager.dart';
import '../../models/kiln_session.dart';
import '../../utils/app_constants.dart';

class FiringSessionScreen extends ConsumerStatefulWidget {
  final int testId;
  final String testName;

  const FiringSessionScreen({
    super.key,
    required this.testId,
    required this.testName,
  });

  @override
  ConsumerState<FiringSessionScreen> createState() => _FiringSessionScreenState();
}

class _FiringSessionScreenState extends ConsumerState<FiringSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kilnController = TextEditingController();
  final _targetTempController = TextEditingController();
  final _peakTempController = TextEditingController();
  final _holdController = TextEditingController();

  String _atmosphere = 'oxidation';
  KilnSession? _existingSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _holdController.text = '10';
  }

  @override
  void dispose() {
    _kilnController.dispose();
    _targetTempController.dispose();
    _peakTempController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    try {
      final storage = StorageManager.instance;
      final sessions = await storage.getKilnSessionsByTestId(widget.testId);

      if (sessions.isNotEmpty) {
        final session = sessions.first;
        setState(() {
          _existingSession = session;
          _kilnController.text = session.kilnId;
          _targetTempController.text = session.targetTemperature.toString();
          _peakTempController.text = session.peakTemperature > 0 ? session.peakTemperature.toString() : '';
          _holdController.text = session.holdMinutes.toString();
          _atmosphere = session.atmosphere;
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startFiring() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final storage = StorageManager.instance;
      final targetTemp = int.parse(_targetTempController.text);
      final holdMinutes = int.parse(_holdController.text);

      final session = KilnSession(
        id: _existingSession?.id,
        testId: widget.testId,
        kilnId: _kilnController.text,
        targetTemperature: targetTemp,
        peakTemperature: _existingSession?.peakTemperature ?? 0,
        holdMinutes: holdMinutes,
        atmosphere: _atmosphere,
        startedAt: _existingSession?.startedAt ?? DateTime.now(),
        completedAt: _existingSession?.completedAt,
      );

      if (_existingSession == null) {
        await storage.createKilnSession(session);

        // Update test status to firing
        final test = await storage.getExperimentRecordById(widget.testId);
        if (test != null) {
          await storage.updateExperimentRecord(test.copyWith(status: 'firing'));
        }
      } else {
        await storage.updateKilnSession(session);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firing session started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeFiring() async {
    if (!_formKey.currentState!.validate()) return;

    final peakTemp = int.tryParse(_peakTempController.text);
    if (peakTemp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter peak temperature'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final storage = StorageManager.instance;
      final targetTemp = int.parse(_targetTempController.text);
      final holdMinutes = int.parse(_holdController.text);

      final session = KilnSession(
        id: _existingSession?.id,
        testId: widget.testId,
        kilnId: _kilnController.text,
        targetTemperature: targetTemp,
        peakTemperature: peakTemp,
        holdMinutes: holdMinutes,
        atmosphere: _atmosphere,
        startedAt: _existingSession?.startedAt ?? DateTime.now(),
        completedAt: DateTime.now(),
      );

      if (_existingSession == null) {
        await storage.createKilnSession(session);
      } else {
        await storage.updateKilnSession(session);
      }

      // Update test status to pending
      final test = await storage.getExperimentRecordById(widget.testId);
      if (test != null) {
        await storage.updateExperimentRecord(test.copyWith(status: 'pending'));
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firing completed! Ready for evaluation'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFiring = _existingSession?.startedAt != null && _existingSession?.completedAt == null;
    final isCompleted = _existingSession?.completedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firing Session'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Card
            if (_existingSession != null)
              Card(
                color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.local_fire_department,
                        color: isCompleted ? Colors.green : Colors.orange,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              isCompleted ? 'COMPLETED' : 'IN PROGRESS',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isCompleted ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Test Info
            Card(
              child: ListTile(
                leading: const Icon(Icons.science),
                title: Text(widget.testName),
                subtitle: const Text('Firing Session'),
              ),
            ),

            const SizedBox(height: 24),

            // Kiln
            TextFormField(
              key: const ValueKey('kiln_field'),
              controller: _kilnController,
              decoration: const InputDecoration(
                labelText: 'Kiln',
                hintText: 'Kiln A',
                prefixIcon: Icon(Icons.local_fire_department),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter kiln name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Target Temperature
            TextFormField(
              key: const ValueKey('target_temp_field'),
              controller: _targetTempController,
              decoration: const InputDecoration(
                labelText: 'Target Temperature (°C)',
                hintText: '1220',
                prefixIcon: Icon(Icons.thermostat),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter target temperature';
                }
                final temp = int.tryParse(value);
                if (temp == null || temp < 500 || temp > 1500) {
                  return 'Invalid temperature (500-1500°C)';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Peak Temperature (only for completing)
            if (isFiring || isCompleted)
              TextFormField(
                key: const ValueKey('peak_temp_field'),
                controller: _peakTempController,
                decoration: InputDecoration(
                  labelText: 'Peak Temperature (°C)',
                  hintText: '1222',
                  prefixIcon: const Icon(Icons.trending_up),
                  enabled: !isCompleted,
                ),
                keyboardType: TextInputType.number,
              ),

            if (isFiring || isCompleted) const SizedBox(height: 16),

            // Hold Time
            TextFormField(
              key: const ValueKey('hold_time_field'),
              controller: _holdController,
              decoration: const InputDecoration(
                labelText: 'Hold Time (minutes)',
                hintText: '10',
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter hold time';
                }
                final time = int.tryParse(value);
                if (time == null || time < 0) {
                  return 'Invalid hold time';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Atmosphere
            DropdownButtonFormField<String>(
              key: const ValueKey('atmosphere_dropdown'),
              value: _atmosphere,
              decoration: const InputDecoration(
                labelText: 'Atmosphere',
                prefixIcon: Icon(Icons.air),
              ),
              items: AppConstants.atmosphereOptions.map((atm) {
                return DropdownMenuItem(
                  value: atm,
                  child: Text(_capitalizeFirst(atm)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _atmosphere = value);
                }
              },
            ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Firing Schedule',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Start firing and monitor temperature\n'
                      '2. Record peak temperature reached\n'
                      '3. Complete firing when done\n'
                      '4. Wait for cooling before evaluation',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            if (!isCompleted) ...[
              if (!isFiring)
                ElevatedButton.icon(
                  key: const ValueKey('start_firing_button'),
                  onPressed: _startFiring,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Firing'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  key: const ValueKey('complete_firing_button'),
                  onPressed: _completeFiring,
                  icon: const Icon(Icons.check),
                  label: const Text('Complete Firing'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],

            // Session Info
            if (_existingSession != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    if (_existingSession!.startedAt != null)
                      ListTile(
                        leading: const Icon(Icons.play_arrow),
                        title: const Text('Started'),
                        trailing: Text(
                          '${_existingSession!.startedAt!.day}/${_existingSession!.startedAt!.month} '
                          '${_existingSession!.startedAt!.hour}:${_existingSession!.startedAt!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    if (_existingSession!.completedAt != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: const Text('Completed'),
                        trailing: Text(
                          '${_existingSession!.completedAt!.day}/${_existingSession!.completedAt!.month} '
                          '${_existingSession!.completedAt!.hour}:${_existingSession!.completedAt!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
