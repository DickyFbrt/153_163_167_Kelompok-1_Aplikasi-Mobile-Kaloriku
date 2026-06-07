import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/food_model.dart';
import '../models/activity_model.dart';

class FirebaseDatabaseService {
  static FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://kaloriku-532de-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

  static DatabaseReference get _dbRef => _db.ref();

  // Enable offline persistence
  static void initialize() {
    try {
      _db.setPersistenceEnabled(true);
    } catch (e) {
      debugPrint('Error enabling Firebase offline persistence: $e');
    }
  }

  // ─── Food Logs ──────────────────────────────────────────
  static Future<void> insertFoodLog(FoodLog log, {required String userId}) async {
    if (userId.isEmpty) return;
    await _dbRef.child('users/$userId/food_logs/${log.id}').set({
      'id': log.id,
      'foodId': log.food.id,
      'foodName': log.food.name,
      'foodEmoji': log.food.emoji,
      'foodCalories': log.food.calories,
      'foodCarbs': log.food.carbs,
      'foodProtein': log.food.protein,
      'foodFat': log.food.fat,
      'foodCategory': log.food.category,
      'servings': log.servings,
      'mealType': log.mealType,
      'loggedAt': log.loggedAt.toIso8601String(),
    });
  }

  static Future<void> deleteFoodLog(String id, {required String userId}) async {
    if (userId.isEmpty) return;
    await _dbRef.child('users/$userId/food_logs/$id').remove();
  }

  static Future<List<FoodLog>> getFoodLogsForDate(String date, {required String userId}) async {
    if (userId.isEmpty) return [];
    try {
      final snapshot = await _dbRef.child('users/$userId/food_logs').get().timeout(const Duration(seconds: 4));
      if (!snapshot.exists) return [];
      
      final Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final List<FoodLog> logs = [];
      data.forEach((key, val) {
        final map = Map<String, dynamic>.from(val as Map);
        final loggedAtStr = map['loggedAt'] as String;
        if (loggedAtStr.startsWith(date)) {
          final food = FoodItem(
            id: map['foodId']?.toString() ?? '',
            name: map['foodName']?.toString() ?? '',
            emoji: map['foodEmoji']?.toString() ?? '',
            calories: (map['foodCalories'] as num?)?.toDouble() ?? 0.0,
            carbs: (map['foodCarbs'] as num?)?.toDouble() ?? 0.0,
            protein: (map['foodProtein'] as num?)?.toDouble() ?? 0.0,
            fat: (map['foodFat'] as num?)?.toDouble() ?? 0.0,
            category: map['foodCategory']?.toString() ?? '',
          );
          logs.add(FoodLog(
            id: map['id']?.toString() ?? key.toString(),
            food: food,
            servings: (map['servings'] as num?)?.toDouble() ?? 1.0,
            mealType: map['mealType']?.toString() ?? '',
            loggedAt: DateTime.parse(loggedAtStr),
          ));
        }
      });
      // Sort by loggedAt ascending
      logs.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
      return logs;
    } catch (e) {
      debugPrint('Error getFoodLogsForDate: $e');
      return [];
    }
  }

  static Future<List<FoodLog>> getAllFoodLogs({required String userId}) async {
    if (userId.isEmpty) return [];
    try {
      final snapshot = await _dbRef.child('users/$userId/food_logs').get().timeout(const Duration(seconds: 4));
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final List<FoodLog> logs = [];
      data.forEach((key, val) {
        final map = Map<String, dynamic>.from(val as Map);
        final food = FoodItem(
          id: map['foodId']?.toString() ?? '',
          name: map['foodName']?.toString() ?? '',
          emoji: map['foodEmoji']?.toString() ?? '',
          calories: (map['foodCalories'] as num?)?.toDouble() ?? 0.0,
          carbs: (map['foodCarbs'] as num?)?.toDouble() ?? 0.0,
          protein: (map['foodProtein'] as num?)?.toDouble() ?? 0.0,
          fat: (map['foodFat'] as num?)?.toDouble() ?? 0.0,
          category: map['foodCategory']?.toString() ?? '',
        );
        logs.add(FoodLog(
          id: map['id']?.toString() ?? key.toString(),
          food: food,
          servings: (map['servings'] as num?)?.toDouble() ?? 1.0,
          mealType: map['mealType']?.toString() ?? '',
          loggedAt: DateTime.parse(map['loggedAt'] as String),
        ));
      });
      // Sort by loggedAt descending
      logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      return logs;
    } catch (e) {
      debugPrint('Error getAllFoodLogs: $e');
      return [];
    }
  }

  // ─── Water Logs ─────────────────────────────────────────
  static Future<void> setWaterForDate(String date, int glasses, {required String userId}) async {
    if (userId.isEmpty) return;
    await _dbRef.child('users/$userId/water_logs/$date').set(glasses);
  }

  static Future<int> getWaterForDate(String date, {required String userId}) async {
    if (userId.isEmpty) return 0;
    try {
      final snapshot = await _dbRef.child('users/$userId/water_logs/$date').get().timeout(const Duration(seconds: 4));
      if (!snapshot.exists) return 0;
      return (snapshot.value as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Error getWaterForDate: $e');
      return 0;
    }
  }

  // ─── Weight History ──────────────────────────────────────
  static Future<void> addWeightEntry(String date, double weightKg, {required String userId}) async {
    if (userId.isEmpty) return;
    await _dbRef.child('users/$userId/weight_history/$date').set(weightKg);
  }

  static Future<List<Map<String, dynamic>>> getWeightHistory({required String userId, int limit = 30}) async {
    if (userId.isEmpty) return [];
    try {
      final snapshot = await _dbRef.child('users/$userId/weight_history').get().timeout(const Duration(seconds: 4));
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final List<Map<String, dynamic>> history = [];
      data.forEach((key, val) {
        history.add({
          'date': key.toString(),
          'weight_kg': (val as num?)?.toDouble() ?? 0.0,
        });
      });
      // Sort by date descending
      history.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
      if (history.length > limit) {
        return history.sublist(0, limit);
      }
      return history;
    } catch (e) {
      debugPrint('Error getWeightHistory: $e');
      return [];
    }
  }

  // ─── Activity Logs (Olahraga) ───────────────────────────
  static Future<void> insertActivityLog({
    required String id,
    required String userId,
    required String date,
    required String activityType,
    required double minutes,
    required double met,
    required double caloriesBurned,
    required DateTime loggedAt,
  }) async {
    if (userId.isEmpty) return;
    await _dbRef.child('users/$userId/activity_logs/$id').set({
      'id': id,
      'date': date,
      'activityType': activityType,
      'minutes': minutes,
      'met': met,
      'caloriesBurned': caloriesBurned,
      'loggedAt': loggedAt.toIso8601String(),
    });
  }

  static Future<List<ActivityLog>> getActivityLogsForDate({
    required String date,
    required String userId,
  }) async {
    if (userId.isEmpty) return [];
    try {
      final snapshot = await _dbRef.child('users/$userId/activity_logs').get().timeout(const Duration(seconds: 4));
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final List<ActivityLog> logs = [];
      data.forEach((key, val) {
        final map = Map<String, dynamic>.from(val as Map);
        if (map['date'] == date) {
          logs.add(ActivityLog(
            id: map['id']?.toString() ?? key.toString(),
            loggedAt: DateTime.parse(map['loggedAt'] as String),
            activityType: map['activityType']?.toString() ?? '',
            minutes: (map['minutes'] as num?)?.toDouble() ?? 0.0,
            met: (map['met'] as num?)?.toDouble() ?? 0.0,
            caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
          ));
        }
      });
      // Sort by loggedAt descending
      logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      return logs;
    } catch (e) {
      debugPrint('Error getActivityLogsForDate: $e');
      return [];
    }
  }

  static Future<double> getTotalCaloriesBurnedForDate({
    required String date,
    required String userId,
  }) async {
    if (userId.isEmpty) return 0.0;
    try {
      final logs = await getActivityLogsForDate(date: date, userId: userId);
      return logs.fold<double>(0.0, (sum, log) => sum + log.caloriesBurned);
    } catch (e) {
      debugPrint('Error getTotalCaloriesBurnedForDate: $e');
      return 0.0;
    }
  }

  static Future<void> deleteActivityLog(String id, {required String userId}) async {
    if (userId.isEmpty) return;
    await _dbRef.child('users/$userId/activity_logs/$id').remove();
  }
}
