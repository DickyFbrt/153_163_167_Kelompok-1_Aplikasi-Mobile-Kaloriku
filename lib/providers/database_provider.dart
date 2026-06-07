import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_model.dart';
import '../models/activity_model.dart';
import '../services/firebase_database_service.dart';

class DatabaseProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // The currently logged-in user's Firebase UID — used to scope all DB queries
  String _userId = '';

  // ─── Food Logs ────────────────────────────────────────
  final List<FoodLog> _foodLogs = [];
  List<FoodLog> get foodLogs => _foodLogs;

  List<FoodLog> get todayLogs {
    final today = _todayKey();
    return _foodLogs.where((l) => _dateKey(l.loggedAt) == today).toList();
  }

  List<FoodLog> logsByMeal(String mealType) =>
      todayLogs.where((l) => l.mealType == mealType).toList();

  double get totalCaloriesToday =>
      todayLogs.fold(0, (s, l) => s + l.totalCalories);
  double get totalCarbsToday => todayLogs.fold(0, (s, l) => s + l.totalCarbs);
  double get totalProteinToday =>
      todayLogs.fold(0, (s, l) => s + l.totalProtein);
  double get totalFatToday => todayLogs.fold(0, (s, l) => s + l.totalFat);

  // ─── Water ────────────────────────────────────────────
  int _waterGlasses = 0;
  int waterGoal = 8;
  int get waterGlasses => _waterGlasses;

  // ─── Stats ────────────────────────────────────────────
  double caloriesBurned = 0;
  List<double> _weeklyCalories = [];
  List<double> get weeklyCalories => _weeklyCalories;

  // ─── Init ─────────────────────────────────────────────
  DatabaseProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Get the current user's Firebase UID
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? '';

    // Target standar kesehatan: 8 gelas per hari
    waterGoal = 8;

    final todayStr = _todayKey();

    // Load today's food logs
    final logs = await FirebaseDatabaseService.getFoodLogsForDate(
      todayStr,
      userId: _userId,
    );
    _foodLogs
      ..clear()
      ..addAll(logs);

    // Load weekly calories based on user login/registration date
    final creationTime = user?.metadata.creationTime ?? DateTime.now();
    final localCreation = creationTime.toLocal();
    final startDate = DateTime(localCreation.year, localCreation.month, localCreation.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(startDate).inDays + 1;
    final numDays = days.clamp(1, 7);

    final allLogs = await FirebaseDatabaseService.getAllFoodLogs(userId: _userId);
    _weeklyCalories = List.generate(numDays, (i) {
      final day = now.subtract(Duration(days: numDays - 1 - i));
      final key = _dateKey(day);
      final dayLogs = allLogs.where((l) => _dateKey(l.loggedAt) == key);
      return dayLogs.fold(0.0, (s, l) => s + l.totalCalories);
    });

    // Load water for today
    _waterGlasses = await FirebaseDatabaseService.getWaterForDate(
      todayStr,
      userId: _userId,
    );

    // Load calories burned from activities for today
    caloriesBurned = await FirebaseDatabaseService.getTotalCaloriesBurnedForDate(
      date: todayStr,
      userId: _userId,
    );

    _isLoading = false;
    notifyListeners();
  }

  // ─── Food Log Methods ─────────────────────────────────

  Future<void> addFoodLog(
      FoodItem food, double servings, String mealType) async {
    final log = FoodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      food: food,
      servings: servings,
      mealType: mealType,
      loggedAt: DateTime.now(),
    );
    _foodLogs.add(log);
    if (_weeklyCalories.isNotEmpty) {
      _weeklyCalories[_weeklyCalories.length - 1] += log.totalCalories;
    }
    notifyListeners();
    await FirebaseDatabaseService.insertFoodLog(log, userId: _userId);
  }

  Future<void> removeFoodLog(String id) async {
    final logIndex = _foodLogs.indexWhere((l) => l.id == id);
    if (logIndex != -1) {
      final log = _foodLogs[logIndex];
      _foodLogs.removeAt(logIndex);
      if (_weeklyCalories.isNotEmpty) {
        _weeklyCalories[_weeklyCalories.length - 1] =
            (_weeklyCalories[_weeklyCalories.length - 1] - log.totalCalories)
                .clamp(0.0, double.infinity);
      }
    }
    notifyListeners();
    await FirebaseDatabaseService.deleteFoodLog(id, userId: _userId);
  }

  // ─── Water Methods ────────────────────────────────────

  Future<void> setWaterGlasses(int count) async {
    _waterGlasses = count.clamp(0, waterGoal);
    notifyListeners();
    await FirebaseDatabaseService.setWaterForDate(
      _todayKey(),
      _waterGlasses,
      userId: _userId,
    );
  }

  Future<void> incrementWater() async {
    if (_waterGlasses < waterGoal) {
      _waterGlasses++;
      notifyListeners();
      await FirebaseDatabaseService.setWaterForDate(
        _todayKey(),
        _waterGlasses,
        userId: _userId,
      );
    }
  }

  Future<void> decrementWater() async {
    if (_waterGlasses > 0) {
      _waterGlasses--;
      notifyListeners();
      await FirebaseDatabaseService.setWaterForDate(
        _todayKey(),
        _waterGlasses,
        userId: _userId,
      );
    }
  }

  Future<void> updateWaterGoal(int newGoal) async {
    // Target standar kesehatan: tetap 8 gelas per hari
    waterGoal = 8;
    notifyListeners();
  }

  // ─── Weekly Data ──────────────────────────────────────

  /// Returns calories consumed per day for the last [days] days
  Future<List<double>> getWeeklyCalories({int days = 7}) async {
    final allLogs = await FirebaseDatabaseService.getAllFoodLogs(userId: _userId);
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      final key = _dateKey(day);
      final dayLogs = allLogs.where((l) => _dateKey(l.loggedAt) == key);
      return dayLogs.fold(0.0, (s, l) => s + l.totalCalories);
    });
  }

  List<String> get weekDayLabels {
    final now = DateTime.now();
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final length = _weeklyCalories.isNotEmpty ? _weeklyCalories.length : 7;
    return List.generate(length, (i) {
      final day = now.subtract(Duration(days: length - 1 - i));
      return days[day.weekday - 1];
    });
  }

  // ─── Activity Log Methods ─────────────────────────────

  Future<void> addActivityLog({
    required String id,
    required String date,
    required String activityType,
    required double minutes,
    required double met,
    required double caloriesBurned,
    required DateTime loggedAt,
  }) async {
    this.caloriesBurned += caloriesBurned;
    notifyListeners();
    await FirebaseDatabaseService.insertActivityLog(
      id: id,
      userId: _userId,
      date: date,
      activityType: activityType,
      minutes: minutes,
      met: met,
      caloriesBurned: caloriesBurned,
      loggedAt: loggedAt,
    );
  }

  Future<List<ActivityLog>> getActivityLogsForDate(String date) async {
    return FirebaseDatabaseService.getActivityLogsForDate(
      date: date,
      userId: _userId,
    );
  }

  Future<void> removeActivityLog(String id, double caloriesBurnedAmount) async {
    caloriesBurned = (caloriesBurned - caloriesBurnedAmount).clamp(0.0, double.infinity);
    notifyListeners();
    await FirebaseDatabaseService.deleteActivityLog(id, userId: _userId);
  }

  // ─── Weight History ───────────────────────────────────

  Future<void> addWeightEntry(String date, double weightKg) async {
    await FirebaseDatabaseService.addWeightEntry(
      date,
      weightKg,
      userId: _userId,
    );
  }

  Future<List<Map<String, dynamic>>> getWeightHistory({int limit = 30}) async {
    return FirebaseDatabaseService.getWeightHistory(
      userId: _userId,
      limit: limit,
    );
  }

  // ─── Health Tips ──────────────────────────────────────
  String get healthTip {
    final hour = DateTime.now().hour;
    if (hour < 9) {
      return 'Awali hari dengan segelas air hangat dan sarapan bergizi!';
    }
    if (hour < 12) {
      return 'Jangan lupa minum air setiap jam untuk tetap terhidrasi.';
    }
    if (hour < 15) {
      return 'Pilih snack sehat seperti buah atau kacang di sore hari.';
    }
    if (hour < 18) {
      return 'Makan malam sebelum jam 7 malam untuk metabolisme optimal.';
    }
    return 'Istirahat cukup 7-8 jam malam ini untuk pemulihan tubuh.';
  }

  // ─── Helpers ──────────────────────────────────────────
  String _todayKey() {
    final now = DateTime.now();
    return _dateKey(now);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Called when user logs in or registers — reloads data for the new active user
  Future<void> reload() => _init();
}
