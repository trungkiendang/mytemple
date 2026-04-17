import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/calendar_event.dart';
import '../../services/hive_service.dart';

class EventProvider extends ChangeNotifier {
  List<CalendarEvent> _events = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CalendarEvent> get events => _events;

  EventProvider() {
    _loadEvents();
  }

  void _loadEvents() {
    _events = HiveService.getAllEvents();
    notifyListeners();
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    return _events.where((event) {
      return event.date.year == date.year &&
          event.date.month == date.month &&
          event.date.day == date.day;
    }).toList();
  }

  Future<void> addEvent(CalendarEvent event) async {
    _events.add(event);
    await HiveService.saveEvent(event);
    notifyListeners();
    _syncToFirestore(event);
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((event) => event.id == id);
    await HiveService.deleteEvent(id);
    notifyListeners();
    _deleteFromFirestore(id);
  }

  Future<void> _syncToFirestore(CalendarEvent event) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('user_events')
            .doc(event.id)
            .set({
          'title': event.title,
          'date': Timestamp.fromDate(event.date),
          'isLunar': event.isLunar,
          'reminderEnabled': event.reminderEnabled,
        });
      } catch (e) {
        debugPrint('Error syncing event to Firestore: $e');
      }
    }
  }

  Future<void> _deleteFromFirestore(String id) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('user_events')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint('Error deleting event from Firestore: $e');
      }
    }
  }
}
