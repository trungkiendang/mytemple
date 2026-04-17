import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:intl/intl.dart';

class LunarCalendarScreen extends StatefulWidget {
  const LunarCalendarScreen({super.key});

  @override
  State<LunarCalendarScreen> createState() => _LunarCalendarScreenState();
}

class _LunarCalendarScreenState extends State<LunarCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  late DateTime _firstDayOfMonth;
  late int _daysInMonth;
  late int _firstWeekdayOfMonth;

  @override
  void initState() {
    super.initState();
    _updateMonthData();
  }

  void _updateMonthData() {
    _firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    _daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    _firstWeekdayOfMonth = _firstDayOfMonth.weekday;
  }

  void _previousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      _updateMonthData();
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      _updateMonthData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Âm Dương'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildWeekdayLabels(),
          Expanded(
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat('MMMM yyyy', 'vi_VN').format(_focusedDay),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Row(
      children: weekdays
          .map((label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    // Adjust for Monday start (weekday 1 is Monday, 7 is Sunday)
    int offset = _firstWeekdayOfMonth - 1;
    int totalCells = ((_daysInMonth + offset) / 7).ceil() * 7;

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        int day = index - offset + 1;
        if (day < 1 || day > _daysInMonth) {
          return const SizedBox.shrink();
        }

        DateTime date = DateTime(_focusedDay.year, _focusedDay.month, day);
        Solar solar = Solar.fromDate(date);
        Lunar lunar = solar.getLunar();

        bool isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return Container(
          margin: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.0),
            color: isToday ? Colors.orange.shade100 : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.orange : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${lunar.getDay()}/${lunar.getMonth()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
