import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CountdownTimer extends StatefulWidget {
  final dynamic setTime;

  CountdownTimer({required this.setTime});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  String _timeLeft = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft = _calculateTimeLeft();
        });
      }
    });
    // Initial calculation
    _timeLeft = _calculateTimeLeft();
  }

  String _calculateTimeLeft() {
    DateTime targetTime;
    if (widget.setTime is Timestamp) {
      targetTime = widget.setTime.toDate();
    } else if (widget.setTime is String) {
      targetTime = DateTime.parse(widget.setTime);
    } else {
      return 'Invalid Date';
    }

    Duration difference = targetTime.difference(DateTime.now());

    if (difference.isNegative) {
      return 'Expired';
    }

    int hours = difference.inHours;
    int minutes = difference.inMinutes.remainder(60);
    int seconds = difference.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.timer, size: 24,color: Colors.orange,),
        SizedBox(width: 4),
        Text(
          _timeLeft,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _timeLeft == 'Expired' ? Colors.red : Colors.orange,
          ),
        ),
      ],
    );
  }
}
