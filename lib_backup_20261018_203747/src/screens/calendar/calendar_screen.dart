import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/storage_manager.dart';
import '../../models/experiment_record.dart';
import '../tests/test_detail_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  List<ExperimentRecord> _tests = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final storage = StorageManager.instance;
      final tests = await storage.getAllExperimentRecords();

      setState(() {
        _tests = tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<ExperimentRecord> _getTestsForDay(DateTime day) {
    return _tests.where((test) {
      return test.testDate.year == day.year &&
             test.testDate.month == day.month &&
             test.testDate.day == day.day;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'preparing':
        return Colors.orange;
      case 'firing':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                    },
                  ),
                  Text(
                    _getMonthYearText(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Calendar Grid
          Expanded(
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: firstWeekday + daysInMonth + 7, // Include day headers
      itemBuilder: (context, index) {
        // Day headers (Sun, Mon, Tue, etc.)
        if (index < 7) {
          final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
          return Center(
            child: Text(
              days[index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        // Empty cells before first day
        final dayIndex = index - 7;
        if (dayIndex < firstWeekday) {
          return const SizedBox();
        }

        // Day cells
        final day = dayIndex - firstWeekday + 1;
        if (day > daysInMonth) {
          return const SizedBox();
        }

        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
        final testsForDay = _getTestsForDay(date);
        final isToday = _isToday(date);

        return GestureDetector(
          onTap: testsForDay.isEmpty
              ? null
              : () => _showDayTests(context, date, testsForDay),
          child: Container(
            decoration: BoxDecoration(
              color: testsForDay.isEmpty
                  ? null
                  : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              border: Border.all(
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: isToday ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : null,
                    color: isToday ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                if (testsForDay.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: testsForDay.take(3).map((test) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _getStatusColor(test.status),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  String _getMonthYearText() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  void _showDayTests(BuildContext context, DateTime date, List<ExperimentRecord> tests) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tests on ${date.day}/${date.month}/${date.year}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...tests.map((test) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(test.status),
                      child: Text(
                        test.targetCone,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(test.name),
                    subtitle: Text(test.status),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestDetailScreen(
                            testId: test.id!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
