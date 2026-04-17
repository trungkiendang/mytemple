import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scripture.dart';
import '../../services/tts_service.dart';

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
  bool _isTtsActive = false;

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

  void _toggleTts() {
    setState(() {
      _isTtsActive = !_isTtsActive;
      if (!_isTtsActive) {
        Provider.of<TtsService>(context, listen: false).stop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    // Stop TTS when navigating away
    if (mounted) {
      Provider.of<TtsService>(context, listen: false).stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scripture.title),
        actions: [
          IconButton(
            icon: Icon(_isTtsActive ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleTts,
          ),
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
      bottomSheet: _isTtsActive ? _buildTtsControlPanel() : null,
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

  Widget _buildTtsControlPanel() {
    return Consumer<TtsService>(
      builder: (context, ttsService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () => ttsService.stop(),
                  ),
                  IconButton(
                    icon: Icon(ttsService.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      if (ttsService.isPlaying) {
                        ttsService.pause();
                      } else {
                        ttsService.speak(widget.scripture.content);
                      }
                    },
                  ),
                  DropdownButton<double>(
                    value: ttsService.rate,
                    items: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5].map((double value) {
                      return DropdownMenuItem<double>(
                        value: value,
                        child: Text('${value}x'),
                      );
                    }).toList(),
                    onChanged: (double? newValue) {
                      if (newValue != null) {
                        ttsService.setRate(newValue);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleTts,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
