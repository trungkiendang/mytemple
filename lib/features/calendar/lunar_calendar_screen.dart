import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';

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
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.woodBrown),
            onPressed: _previousMonth,
          ),
          Column(
            children: [
              Text(
                DateFormat('MMMM', 'vi_VN').format(_focusedDay).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkWood,
                ),
              ),
              Text(
                DateFormat('yyyy').format(_focusedDay),
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.darkWood.withOpacity(0.6),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.woodBrown),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppTheme.woodBrown.withOpacity(0.05),
      child: Row(
        children: weekdays
            .map((label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.woodBrown,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    int offset = _firstWeekdayOfMonth - 1;
    int totalCells = ((_daysInMonth + offset) / 7).ceil() * 7;

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.75,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
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

        bool isSpecialDay = lunar.getDay() == 1 || lunar.getDay() == 15;

        return Container(
          decoration: BoxDecoration(
            color: isToday ? AppTheme.woodBrown : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
            border: isSpecialDay
                ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : AppTheme.darkWood,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${lunar.getDay()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSpecialDay ? FontWeight.bold : FontWeight.normal,
                  color: isToday
                      ? Colors.white70
                      : (isSpecialDay ? Colors.orange.shade700 : Colors.grey),
                ),
              ),
              if (lunar.getDay() == 1)
                Text(
                  'Tháng ${lunar.getMonth()}',
                  style: TextStyle(
                    fontSize: 8,
                    color: isToday ? Colors.white60 : Colors.orange.shade700,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.orange, 'Ngày Rằm/Mồng 1'),
          const SizedBox(width: 20),
          _buildLegendItem(AppTheme.woodBrown, 'Hôm nay'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.darkWood),
        ),
      ],
    );
  }
}
