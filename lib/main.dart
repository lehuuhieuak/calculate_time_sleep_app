import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeNotifier,
      builder: (context, child) {
        return MaterialApp(
          title: 'Máy Tính Chu Kỳ Giấc Ngủ',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            platform: Platform.isIOS ? TargetPlatform.iOS : TargetPlatform.android,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            platform: Platform.isIOS ? TargetPlatform.iOS : TargetPlatform.android,
          ),
          themeMode: _themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: SleepCycleCalculatorScreen(themeNotifier: _themeNotifier),
        );
      },
    );
  }
}

class SleepCycleCalculatorScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  
  const SleepCycleCalculatorScreen({super.key, required this.themeNotifier});

  @override
  State<SleepCycleCalculatorScreen> createState() => _SleepCycleCalculatorScreenState();
}

class _SleepCycleCalculatorScreenState extends State<SleepCycleCalculatorScreen> {
  TimeOfDay? _selectedTime;
  bool _isBedtime = true; // true for bedtime, false for wake-up time
  List<TimeOfDay> _calculatedTimes = [];
  int _fallAsleepMinutes = 15;

  // Sleep cycle duration in minutes (typically 90 minutes)
  static const int _sleepCycleDuration = 90;

  void _selectTime() async {
    TimeOfDay? picked;
    
    if (Platform.isIOS) {
      // Use Cupertino-style time picker for iOS
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) {
          DateTime tempPickedDate = DateTime.now();
          return Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Container(
                  height: 50,
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Hủy'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      CupertinoButton(
                        child: const Text('Xong'),
                        onPressed: () {
                          picked = TimeOfDay.fromDateTime(tempPickedDate);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: _selectedTime != null 
                        ? DateTime(2024, 1, 1, _selectedTime!.hour, _selectedTime!.minute)
                        : DateTime.now(),
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempPickedDate = newDateTime;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Use Material time picker for Android
      picked = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
      );
    }
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _calculateOptimalTimes();
      });
    }
  }

  void _calculateOptimalTimes() {
    if (_selectedTime == null) return;

    List<TimeOfDay> times = [];
    DateTime baseTime = DateTime(2024, 1, 1, _selectedTime!.hour, _selectedTime!.minute);

    if (_isBedtime) {
      // Calculate wake-up times from bedtime
      // Add time to fall asleep
      DateTime sleepTime = baseTime.add(Duration(minutes: _fallAsleepMinutes));
      
      // Calculate 4-6 sleep cycles (6-9 hours of sleep)
      for (int cycles = 4; cycles <= 6; cycles++) {
        DateTime wakeTime = sleepTime.add(Duration(minutes: cycles * _sleepCycleDuration));
        times.add(TimeOfDay.fromDateTime(wakeTime));
      }
    } else {
      // Calculate bedtimes from desired wake-up time
      // Subtract time to fall asleep
      DateTime wakeTime = baseTime.subtract(Duration(minutes: _fallAsleepMinutes));
      
      // Calculate 4-6 sleep cycles (6-9 hours of sleep)
      for (int cycles = 4; cycles <= 6; cycles++) {
        DateTime bedTime = wakeTime.subtract(Duration(minutes: cycles * _sleepCycleDuration));
        times.add(TimeOfDay.fromDateTime(bedTime));
      }
      times = times.reversed.toList(); // Show earliest bedtime first
    }

    setState(() {
      _calculatedTimes = times;
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  String _getSleepDuration(int cycles) {
    final hours = (cycles * _sleepCycleDuration) ~/ 60;
    final minutes = (cycles * _sleepCycleDuration) % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('Máy Tính Chu Kỳ Giấc Ngủ'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: AnimatedBuilder(
                  animation: widget.themeNotifier,
                  builder: (context, child) {
                    return Icon(
                      widget.themeNotifier.isDarkMode 
                          ? CupertinoIcons.sun_max 
                          : CupertinoIcons.moon,
                      size: 24,
                    );
                  },
                ),
                onPressed: () {
                  widget.themeNotifier.toggleTheme();
                },
              ),
            ),
            child: SafeArea(
              child: _buildBody(context),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Máy Tính Chu Kỳ Giấc Ngủ'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: [
                AnimatedBuilder(
                  animation: widget.themeNotifier,
                  builder: (context, child) {
                    return IconButton(
                      icon: Icon(
                        widget.themeNotifier.isDarkMode 
                            ? Icons.light_mode 
                            : Icons.dark_mode,
                      ),
                      onPressed: () {
                        widget.themeNotifier.toggleTheme();
                      },
                      tooltip: widget.themeNotifier.isDarkMode 
                          ? 'Chế độ sáng' 
                          : 'Chế độ tối',
                    );
                  },
                ),
              ],
            ),
            body: _buildBody(context),
          );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          'Thông Tin Chu Kỳ Giấc Ngủ',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                    const SizedBox(height: 8),
                    const Text(
                      'Một chu kỳ giấc ngủ hoàn chỉnh kéo dài khoảng 90 phút. Thức dậy vào cuối chu kỳ giúp bạn cảm thấy sảng khoái và tỉnh táo hơn.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hầu hết người lớn cần 4-6 chu kỳ giấc ngủ hoàn chỉnh (6-9 giờ) mỗi đêm để nghỉ ngơi tối ưu.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tính Toán Từ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    Platform.isIOS 
                        ? CupertinoSlidingSegmentedControl<bool>(
                            children: const {
                              true: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.bed_double, size: 16),
                                    SizedBox(width: 8),
                                    Text('Giờ Đi Ngủ'),
                                  ],
                                ),
                              ),
                              false: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.alarm, size: 16),
                                    SizedBox(width: 8),
                                    Text('Giờ Thức Dậy'),
                                  ],
                                ),
                              ),
                            },
                            groupValue: _isBedtime,
                            onValueChanged: (bool? value) {
                              if (value != null) {
                                setState(() {
                                  _isBedtime = value;
                                  if (_selectedTime != null) {
                                    _calculateOptimalTimes();
                                  }
                                });
                              }
                            },
                          )
                        : SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('Giờ Đi Ngủ'),
                                icon: Icon(Icons.bedtime),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Giờ Thức Dậy'),
                                icon: Icon(Icons.alarm),
                              ),
                            ],
                            selected: {_isBedtime},
                            onSelectionChanged: (Set<bool> selection) {
                              setState(() {
                                _isBedtime = selection.first;
                                if (_selectedTime != null) {
                                  _calculateOptimalTimes();
                                }
                              });
                            },
                          ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Text(
                          'Thời gian để ngủ: ',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Expanded(
                          child: Platform.isIOS
                              ? CupertinoSlider(
                                  value: _fallAsleepMinutes.toDouble(),
                                  min: 5,
                                  max: 30,
                                  divisions: 5,
                                  onChanged: (value) {
                                    setState(() {
                                      _fallAsleepMinutes = value.round();
                                      if (_selectedTime != null) {
                                        _calculateOptimalTimes();
                                      }
                                    });
                                  },
                                )
                              : Slider(
                                  value: _fallAsleepMinutes.toDouble(),
                                  min: 5,
                                  max: 30,
                                  divisions: 5,
                                  label: '$_fallAsleepMinutes phút',
                                  onChanged: (value) {
                                    setState(() {
                                      _fallAsleepMinutes = value.round();
                                      if (_selectedTime != null) {
                                        _calculateOptimalTimes();
                                      }
                                    });
                                  },
                                ),
                        ),
                        if (Platform.isIOS) 
                          Text(
                            '$_fallAsleepMinutes phút',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: Platform.isIOS
                          ? CupertinoButton.filled(
                              onPressed: _selectTime,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(CupertinoIcons.clock, color: CupertinoColors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedTime == null
                                        ? 'Chọn ${_isBedtime ? 'Giờ Đi Ngủ' : 'Giờ Thức Dậy'}'
                                        : '${_isBedtime ? 'Giờ Đi Ngủ' : 'Giờ Thức Dậy'}: ${_formatTime(_selectedTime!)}',
                                    style: const TextStyle(color: CupertinoColors.white),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                _selectedTime == null
                                    ? 'Chọn ${_isBedtime ? 'Giờ Đi Ngủ' : 'Giờ Thức Dậy'}'
                                    : '${_isBedtime ? 'Giờ Đi Ngủ' : 'Giờ Thức Dậy'}: ${_formatTime(_selectedTime!)}',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_calculatedTimes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isBedtime ? 'Giờ Thức Dậy Tối Ưu' : 'Giờ Đi Ngủ Tối Ưu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isBedtime 
                            ? 'Dựa trên giờ đi ngủ của bạn, đây là những thời điểm tốt nhất để thức dậy:'
                            : 'Để thức dậy vào thời gian mong muốn, hãy đi ngủ vào một trong những thời điểm sau:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      ...List.generate(_calculatedTimes.length, (index) {
                        final time = _calculatedTimes[index];
                        final cycles = _isBedtime ? index + 4 : 6 - index;
                        final duration = _getSleepDuration(cycles);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                '${cycles}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              _formatTime(time),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('$duration giấc ngủ ($cycles chu kỳ)'),
                            trailing: Icon(
                              cycles == 5 ? Icons.star : Icons.schedule,
                              color: cycles == 5 
                                  ? Colors.amber 
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Khuyến nghị: 5 chu kỳ (7.5 giờ) là tối ưu cho hầu hết người lớn',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
  }
}
