import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/scripture.dart';

class ScriptureDetailScreen extends StatefulWidget {
  final Scripture scripture;

  const ScriptureDetailScreen({super.key, required this.scripture});

  @override
  State<ScriptureDetailScreen> createState() => _ScriptureDetailScreenState();
}

class _ScriptureDetailScreenState extends State<ScriptureDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool _isAutoScrolling = false;
  double _scrollSpeed = 1.0;

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
      if (_isAutoScrolling) {
        _startAutoScroll();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.offset;
        if (currentScroll < maxScroll) {
          _scrollController.jumpTo(currentScroll + _scrollSpeed);
        } else {
          _timer?.cancel();
          setState(() {
            _isAutoScrolling = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scripture.title),
        actions: [
          IconButton(
            icon: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoScroll,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Text(
            widget.scripture.content,
            style: const TextStyle(fontSize: 18.0, height: 1.5),
          ),
        ),
      ),
      floatingActionButton: _isAutoScrolling
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'speed_up',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _scrollSpeed += 0.5;
                    });
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'speed_down',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      if (_scrollSpeed > 0.5) _scrollSpeed -= 0.5;
                    });
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            )
          : null,
    );
  }
}
