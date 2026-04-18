import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_theme.dart';
import '../../models/calendar_event.dart';
import 'event_provider.dart';

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

  void _showEventBottomSheet(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Consumer<EventProvider>(
            builder: (context, eventProvider, child) {
              final events = eventProvider.getEventsForDate(date);
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sự kiện ${DateFormat('dd/MM').format(date)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkWood,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppTheme.woodBrown, size: 28),
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddEventDialog(date);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.0),
                        child: Center(
                          child: Text(
                            'Không có sự kiện nào',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: events.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.woodBrown.withOpacity(0.1),
                                child: Icon(
                                  event.isLunar ? Icons.brightness_2 : Icons.calendar_today,
                                  color: AppTheme.woodBrown,
                                  size: 20,
                                ),
                              ),
                              title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(event.isLunar ? 'Lặp theo Âm lịch' : 'Dương lịch'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => eventProvider.deleteEvent(event.id),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddEventDialog(DateTime date) {
    final titleController = TextEditingController();
    bool isLunar = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Thêm sự kiện mới'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề sự kiện',
                      hintText: 'Ví dụ: Giỗ ông nội',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Lặp theo lịch âm'),
                    value: isLunar,
                    onChanged: (value) => setState(() => isLunar = value),
                    activeColor: AppTheme.woodBrown,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final event = CalendarEvent(
                        id: const Uuid().v4(),
                        title: titleController.text,
                        date: date,
                        isLunar: isLunar,
                      );
                      context.read<EventProvider>().addEvent(event);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.woodBrown,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lưu sự kiện'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Âm Dương'),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _buildHeader(),
              _buildWeekdayLabels(),
              Expanded(
                child: _buildCalendarGrid(constraints),
              ),
              _buildLegend(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.woodBrown, size: 30),
            onPressed: _previousMonth,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('MMMM', 'vi_VN').format(_focusedDay).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                Text(
                  DateFormat('yyyy').format(_focusedDay),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.darkWood.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.woodBrown, size: 30),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.woodBrown.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: weekdays
            .map((label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.woodBrown,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(BoxConstraints constraints) {
    int offset = _firstWeekdayOfMonth - 1;
    int totalCells = ((_daysInMonth + offset) / 7).ceil() * 7;

    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.85, // Adjusted for better fit
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
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
            bool hasEvents = eventProvider.getEventsForDate(date).isNotEmpty;

            return GestureDetector(
              onTap: () => _showEventBottomSheet(date),
              child: Container(
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.woodBrown : Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    if (!isToday)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                  ],
                  border: isSpecialDay
                      ? Border.all(color: Colors.orange.shade300, width: 1)
                      : (hasEvents
                          ? Border.all(color: AppTheme.woodBrown.withOpacity(0.2), width: 1)
                          : Border.all(color: Colors.grey.shade100, width: 0.5)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.white : AppTheme.darkWood,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            child: Text(
                              '${lunar.getDay()}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSpecialDay ? FontWeight.bold : FontWeight.normal,
                                color: isToday
                                    ? Colors.white70
                                    : (isSpecialDay ? Colors.orange.shade800 : Colors.grey),
                              ),
                            ),
                          ),
                          if (lunar.getDay() == 1)
                            FittedBox(
                              child: Text(
                                'T${lunar.getMonth()}',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? Colors.white60 : Colors.orange.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (hasEvents)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(Colors.orange, 'Rằm/Mồng 1'),
          _buildLegendItem(Colors.red, 'Sự kiện'),
          _buildLegendItem(AppTheme.woodBrown, 'Hôm nay'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.darkWood, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
