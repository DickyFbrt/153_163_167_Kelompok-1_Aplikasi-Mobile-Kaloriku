import 'package:flutter/foundation.dart';

@immutable
class ActivityLog {
  final String id;
  final DateTime loggedAt;
  final String activityType;
  final double minutes;
  final double met;
  final double caloriesBurned;

  const ActivityLog({
    required this.id,
    required this.loggedAt,
    required this.activityType,
    required this.minutes,
    required this.met,
    required this.caloriesBurned,
  });
}
