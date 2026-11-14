import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/output_estimator.dart';
import '../../services/cycle_analytics.dart';

class ProductionCalculatorScreen extends StatefulWidget {
  final int? initialCycleMs;

  const ProductionCalculatorScreen({
    super.key,
    this.initialCycleMs,
  });

  @override
  State<ProductionCalculatorScreen> createState() =>
      _ProductionCalculatorScreenState();
}

class _ProductionCalculatorScreenState
    extends State<ProductionCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Input controllers
  final _cycleTimeController = TextEditingController();
  final _shiftHoursController = TextEditingController(text: '8');
  final _shiftMinutesController = TextEditingController(text: '0');
  final _breakMinutesController = TextEditingController(text: '30');
  final _efficiencyController = TextEditingController(text: '85');
  final _targetQuantityController = TextEditingController();

  String _timeUnit = 'seconds';
  ProductionCalculation? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialCycleMs != null) {
      _cycleTimeController.text =
          (widget.initialCycleMs! / 1000).toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _cycleTimeController.dispose();
    _shiftHoursController.dispose();
    _shiftMinutesController.dispose();
    _breakMinutesController.dispose();
    _efficiencyController.dispose();
    _targetQuantityController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final cycleTime = double.tryParse(_cycleTimeController.text) ?? 0;
    final cycleMs =
        StatisticsService.parseDuration(cycleTime.toString(), _timeUnit);

    final shiftHours = int.tryParse(_shiftHoursController.text) ?? 0;
    final shiftMinutes = int.tryParse(_shiftMinutesController.text) ?? 0;
    final shiftMs = (shiftHours * 60 + shiftMinutes) * 60 * 1000;

    final breakMinutes = int.tryParse(_breakMinutesController.text) ?? 0;
    final breakMs = breakMinutes * 60 * 1000;

    final efficiency = double.tryParse(_efficiencyController.text) ?? 0;

    final targetQty = _targetQuantityController.text.isEmpty
        ? null
        : int.tryParse(_targetQuantityController.text);

    final result = ProductionCalculator.calculate(
      avgCycleMs: cycleMs,
      shiftDurationMs: shiftMs,
      breakDurationMs: breakMs,
      efficiency: efficiency,
      targetQuantity: targetQty,
    );

    setState(() {
      _result = result;
    });
  }

  void _clear() {
    setState(() {
      _cycleTimeController.clear();
      _shiftHoursController.text = '8';
      _shiftMinutesController.text = '0';
      _breakMinutesController.text = '30';
      _efficiencyController.text = '85';
      _targetQuantityController.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bench planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clear,
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Plan the bench',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estimate how many vessels fit the day from pour time, bench hours, pauses, and pace.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cycle Time
            Text(
              'Vessel time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: const ValueKey('cycle_time_field'),
                    controller: _cycleTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Average vessel time *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _timeUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'seconds',
                        child: Text('Seconds'),
                      ),
                      DropdownMenuItem(
                        value: 'minutes',
                        child: Text('Minutes'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _timeUnit = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Shift Duration
            Text(
              'Bench hours',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _shiftHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Bench hours *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _shiftMinutesController,
                    decoration: const InputDecoration(
                      labelText: 'Minutes *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num < 0 || num >= 60) {
                        return '0-59';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breakMinutesController,
              decoration: const InputDecoration(
                labelText: 'Pause time (minutes) *',
                border: OutlineInputBorder(),
                helperText: 'Pauses, setup, and time away from the pot',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                final num = int.tryParse(value);
                if (num == null || num < 0) {
                  return 'Must be >= 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Efficiency
            Text(
              'Pouring pace',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _efficiencyController,
              decoration: const InputDecoration(
                labelText: 'Pouring pace (%) *',
                border: OutlineInputBorder(),
                suffixText: '%',
                helperText: 'How much of the bench time is actual pouring',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                final num = double.tryParse(value);
                if (num == null || num <= 0 || num > 100) {
                  return '0-100';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Target (Optional)
            Text(
              'Target (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetQuantityController,
              decoration: const InputDecoration(
                labelText: 'Vessels to finish',
                border: OutlineInputBorder(),
                helperText: 'Leave empty if you are not filling an order',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 32),

            // Calculate button
            FilledButton.icon(
              key: const ValueKey('calculate_button'),
              onPressed: _calculate,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_result != null) ...[
              if (_result!.isValid)
                _buildResults(_result!)
              else
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _result!.errorMessage ?? 'Calculation error',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ProductionCalculation result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Results',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        // Output
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vessels for the day',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Divider(),
                _buildResultRow(
                  'Straight through',
                  '${result.theoreticalOutput} vessels',
                  'If every minute is a pour',
                ),
                _buildResultRow(
                  'Likely count',
                  '${result.estimatedOutput} vessels',
                  'After ${_efficiencyController.text}% pouring pace',
                  isHighlight: true,
                ),
              ],
            ),
          ),
        ),

        // Target analysis (if target provided)
        if (_targetQuantityController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order check',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  _buildResultRow(
                    'Target Quantity',
                    '${_targetQuantityController.text} vessels',
                    null,
                  ),
                  _buildResultRow(
                    'Time Required',
                    ProductionCalculator.formatTimeHoursMinutes(
                        result.timeRequiredMs),
                    'Hours to finish that order at this pace',
                  ),
                  _buildResultRow(
                    'Needed vessel time',
                    '${StatisticsService.formatDuration(result.requiredCycleMs)} s',
                    'Pace required to finish in the time you have',
                  ),
                  _buildResultRow(
                    result.outputDeficit >= 0 ? 'Deficit' : 'Surplus',
                    '${result.outputDeficit.abs()} vessels',
                    result.outputDeficit >= 0
                        ? 'Short of target'
                        : 'Exceeds target',
                    isHighlight: true,
                    color: result.outputDeficit >= 0
                        ? Colors.red
                        : Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Assumptions
        Card(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Assumptions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Net time = Bench hours − pause time\n'
                  '• Straight through = Net time ÷ vessel time\n'
                  '• Likely count = Straight through × pouring pace\n'
                  '• Counts are rounded down to whole vessels',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    String? description, {
    bool isHighlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isHighlight ? FontWeight.bold : null,
                      color: color,
                    ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
