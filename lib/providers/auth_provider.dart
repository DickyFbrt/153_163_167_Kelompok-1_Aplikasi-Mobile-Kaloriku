import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://kaloriku-532de-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

  static FirebaseDatabase get _staticDb => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://kaloriku-532de-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
  bool _isLoggedIn = false;
  bool _isLoading = true; // loading saat cek sesi
  bool _isFirstTime = true;

  String _userName = '';
  String _email = '';
  double _targetCalories = 2000;
  double _weightKg = 60;
  double _heightCm = 165;
  int _age = 20;
  String _gender = 'Laki-laki';

  // Google sign up active session data
  bool _isGoogleSignUpActive = false;
  String _googleSignUpUid = '';
  String _googleSignUpName = '';
  String _googleSignUpEmail = '';

  bool get isGoogleSignUpActive => _isGoogleSignUpActive;
  String get googleSignUpUid => _googleSignUpUid;
  String get googleSignUpName => _googleSignUpName;
  String get googleSignUpEmail => _googleSignUpEmail;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isFirstTime => _isFirstTime;

  String get userName => _userName;
  String get email => _email;
  double get targetCalories => _targetCalories;
  double get weightKg => _weightKg;
  double get heightCm => _heightCm;
  int get age => _age;
  String get gender => _gender;

  AuthProvider() {
    _initFirebase();
  }

  void _initFirebase() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _email = user.email ?? '';
        final prefs = await SharedPreferences.getInstance();
        _isFirstTime = prefs.getBool('is_first_time') ?? false;

        // Cek profil secara aman di background tanpa memblokir stream listener utama
        _checkAndLoadProfile(user);
      } else {
        _isLoggedIn = false;
        _isFirstTime = true;
        _clearProfile();
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _checkAndLoadProfile(User user) async {
    try {
      // Dapatkan data profil dengan limit timeout 4 detik untuk mencegah stuck selamanya
      final snapshot = await _db
          .ref('users/${user.uid}/profile')
          .get()
          .timeout(const Duration(seconds: 4));

      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          _userName = data['name']?.toString() ?? user.displayName ?? '';
          _targetCalories = (data['targetCalories'] as num?)?.toDouble() ?? 2000.0;
          _weightKg = (data['weightKg'] as num?)?.toDouble() ?? 60.0;
          _heightCm = (data['heightCm'] as num?)?.toDouble() ?? 165.0;
          _age = (data['age'] as num?)?.toInt() ?? 20;
          _gender = data['gender']?.toString() ?? 'Laki-laki';
        }
        _isLoggedIn = true;
      } else {
        // Profil tidak ditemukan di DB
        if (!_isGoogleSignUpActive) {
          // Bersihkan sesi jika bukan pendaftaran Google aktif
          await FirebaseAuth.instance.signOut();
          await _safeGoogleSignOut();
          _isLoggedIn = false;
          _clearProfile();
        } else {
          _isLoggedIn = false;
        }
      }
    } on TimeoutException {
      debugPrint('Timeout checking profile - database may be unreachable');
      if (!_isGoogleSignUpActive) {
        _isLoggedIn = false;
        _clearProfile();
      } else {
        _isLoggedIn = false;
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase error checking profile: ${e.code} - ${e.message}');
      if (!_isGoogleSignUpActive) {
        _isLoggedIn = false;
        _clearProfile();
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      debugPrint('Error checking profile in background: $e');
      if (!_isGoogleSignUpActive) {
        _isLoggedIn = false;
        _clearProfile();
      } else {
        _isLoggedIn = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfileFromFirebase(String uid) async {
    try {
      final snapshot = await _db
          .ref('users/$uid/profile')
          .get()
          .timeout(const Duration(seconds: 4));

      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          _userName = data['name']?.toString() ?? '';
          _targetCalories = (data['targetCalories'] as num?)?.toDouble() ?? 2000.0;
          _weightKg = (data['weightKg'] as num?)?.toDouble() ?? 60.0;
          _heightCm = (data['heightCm'] as num?)?.toDouble() ?? 165.0;
          _age = (data['age'] as num?)?.toInt() ?? 20;
          _gender = data['gender']?.toString() ?? 'Laki-laki';
          notifyListeners();
        }
      }
    } on TimeoutException {
      debugPrint('Timeout loading profile from Firebase');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error loading profile: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('Error loading profile from Firebase: $e');
    }
  }

  void _clearProfile() {
    _userName = '';
    _email = '';
    _targetCalories = 2000;
    _weightKg = 60;
    _heightCm = 165;
    _age = 20;
    _gender = 'Laki-laki';
  }

  Future<void> _safeGoogleSignOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Google Sign-In signOut error: $e');
    }
  }

  /// Login sederhana dengan email & password menggunakan Firebase Auth
  Future<String?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Email dan password tidak boleh kosong.';
    }
    if (!email.contains('@')) {
      return 'Format email tidak valid.';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter.';
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_first_time', false);
        _isFirstTime = false;
        _loadProfileFromFirebase(credential.user!.uid); // load di background
        notifyListeners();
      }
      return null; // Sukses
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Email atau password salah. Pastikan akun sudah terdaftar.';
      } else if (e.code == 'invalid-email') {
        return 'Format email tidak valid.';
      } else if (e.code == 'user-disabled') {
        return 'Akun ini telah dinonaktifkan.';
      }
      return e.message ?? 'Gagal login: ${e.code}';
    } catch (e) {
      return 'Terjadi kesalahan saat login: $e';
    }
  }

  /// Login/Daftar menggunakan Akun Google & Hubungkan ke Firebase Auth
  Future<String?> loginWithGoogle({bool isRegister = false}) async {
    try {
      // 1. Trigger dialog pemilihan akun Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return 'Masuk dengan Google dibatalkan.'; // Pengguna menutup dialog
      }

      // 2. Dapatkan token autentikasi Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Buat kredensial Firebase Auth dari token Google
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase menggunakan kredensial Google
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final uid = user.uid;

        // 5. Periksa apakah data profil pengguna sudah ada di database
        final profileRef = _db.ref('users/$uid/profile');
        DataSnapshot snapshot;
        try {
          snapshot = await profileRef.get().timeout(const Duration(seconds: 4));
        } on TimeoutException {
          await FirebaseAuth.instance.signOut();
          await _safeGoogleSignOut();
          return 'Koneksi ke database timeout. Pastikan internet stabil dan coba lagi.';
        } on FirebaseException catch (e) {
          await FirebaseAuth.instance.signOut();
          await _safeGoogleSignOut();
          if (e.code == 'permission-denied') {
            return 'Akses database ditolak. Silakan hubungi pengembang untuk memperbaiki aturan database.';
          }
          return 'Error database: ${e.message}';
        }

        if (isRegister) {
          // Alur Pendaftaran (Registrasi)
          if (snapshot.exists) {
            // Akun sudah terdaftar sebelumnya
            _isGoogleSignUpActive = false;
            // Muat data profilnya agar user bisa login langsung
            final data = snapshot.value as Map?;
            if (data != null) {
              _userName = data['name']?.toString() ?? user.displayName ?? 'Pengguna Google';
              _email = user.email ?? '';
              _weightKg = (data['weightKg'] as num?)?.toDouble() ?? 60.0;
              _heightCm = (data['heightCm'] as num?)?.toDouble() ?? 165.0;
              _age = (data['age'] as num?)?.toInt() ?? 20;
              _gender = data['gender']?.toString() ?? 'Laki-laki';
              _targetCalories = (data['targetCalories'] as num?)?.toDouble() ?? 2000.0;
            }
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_first_time', false);
            _isLoggedIn = true;
            _isFirstTime = false;
            notifyListeners();
            return 'Akun sudah terdaftar, silakan masuk menggunakan tombol Masuk dengan Google.';
          } else {
            // Akun baru, simpan ke state pendaftaran Google aktif
            _isGoogleSignUpActive = true;
            _googleSignUpUid = uid;
            _googleSignUpName = user.displayName ?? '';
            _googleSignUpEmail = user.email ?? '';
            _isLoggedIn = false;
            notifyListeners();
            return null; // Sukses tahap awal
          }
        } else {
          // Alur Masuk (Login)
          if (!snapshot.exists) {
            // Akun belum terdaftar
            _isGoogleSignUpActive = false;
            // Bersihkan sesi
            await FirebaseAuth.instance.signOut();
            await _safeGoogleSignOut();
            _isLoggedIn = false;
            _clearProfile();
            notifyListeners();
            return 'Akun tidak terdaftar, mohon daftar terlebih dahulu.';
          } else {
            // Akun ada, muat profil
            final data = snapshot.value as Map?;
            if (data != null) {
              _userName = data['name']?.toString() ?? user.displayName ?? 'Pengguna Google';
              _email = user.email ?? '';
              _weightKg = (data['weightKg'] as num?)?.toDouble() ?? 60.0;
              _heightCm = (data['heightCm'] as num?)?.toDouble() ?? 165.0;
              _age = (data['age'] as num?)?.toInt() ?? 20;
              _gender = data['gender']?.toString() ?? 'Laki-laki';
              _targetCalories = (data['targetCalories'] as num?)?.toDouble() ?? 2000.0;
            }
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_first_time', false);
            _isLoggedIn = true;
            _isFirstTime = false;
            notifyListeners();
            return null; // Sukses login
          }
        }
      }
      return 'Gagal mendapatkan data pengguna Google.';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Google Error: $e');
      return e.message ?? 'Gagal masuk dengan Google: ${e.code}';
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return 'Terjadi kesalahan saat masuk dengan Google: $e';
    }
  }

  /// Melengkapi profil registrasi Google dengan data tubuh & target kalori
  Future<String?> registerWithGoogleProfile({
    required String name,
    required double weight,
    required double height,
    required int age,
    required String gender,
    required double targetCalories,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'Sesi Google Anda telah berakhir. Silakan coba mendaftar lagi.';
    }
    final uid = user.uid;

    try {
      await _db.ref('users/$uid/profile').set({
        'name': name.trim(),
        'weightKg': weight,
        'heightCm': height,
        'age': age,
        'gender': gender,
        'targetCalories': targetCalories,
      }).timeout(const Duration(seconds: 4));

      // Simpan email terdaftar ke indeks pencarian
      if (user.email != null && user.email!.isNotEmpty) {
        final sanitizedEmail = user.email!.trim().toLowerCase().replaceAll('.', '_');
        await _db.ref('emails_index/$sanitizedEmail').set(true).timeout(const Duration(seconds: 4));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_time', false);

      _userName = name.trim();
      _email = user.email ?? '';
      _weightKg = weight;
      _heightCm = height;
      _age = age;
      _gender = gender;
      _targetCalories = targetCalories;
      _isLoggedIn = true;
      _isFirstTime = false;
      _isGoogleSignUpActive = false; // reset active sign up

      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error register Google profile: $e');
      return 'Gagal menyimpan data pendaftaran: $e';
    }
  }

  /// Daftar akun baru + simpan data onboarding ke Firebase Auth & Realtime Database
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required double weight,
    required double height,
    required int age,
    required String gender,
    required double targetCalories,
  }) async {
    if (name.trim().isEmpty) return 'Nama tidak boleh kosong.';
    if (email.isEmpty || !email.contains('@')) return 'Format email tidak valid.';
    if (password.length < 6) return 'Password minimal 6 karakter.';

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;

        // Simpan data profil ke Firebase Realtime Database
        await _db.ref('users/$uid/profile').set({
          'name': name.trim(),
          'weightKg': weight,
          'heightCm': height,
          'age': age,
          'gender': gender,
          'targetCalories': targetCalories,
        }).timeout(const Duration(seconds: 4));

        // Simpan email terdaftar ke indeks pencarian
        final sanitizedEmail = email.trim().toLowerCase().replaceAll('.', '_');
        await _db.ref('emails_index/$sanitizedEmail').set(true).timeout(const Duration(seconds: 4));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_first_time', false);

        _userName = name.trim();
        _email = email.trim();
        _weightKg = weight;
        _heightCm = height;
        _age = age;
        _gender = gender;
        _targetCalories = targetCalories;
        _isLoggedIn = true;
        _isFirstTime = false;

        notifyListeners();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk.';
      } else if (e.code == 'invalid-email') {
        return 'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        return 'Password terlalu lemah.';
      }
      return e.message ?? 'Gagal mendaftar: ${e.code}';
    } catch (e) {
      return 'Terjadi kesalahan saat pendaftaran: $e';
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await _safeGoogleSignOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    _isLoggedIn = false;
    _clearProfile();
    notifyListeners();
  }

  Future<String?> updateProfile({
    required String name,
    required double weight,
    required double height,
    required int age,
    required String gender,
    required double targetCalories,
  }) async {
    if (name.trim().isEmpty) {
      return 'Nama tidak boleh kosong.';
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    }

    try {
      // Jalankan update di background tanpa memblokir (fire-and-forget)
      _db.ref('users/${user.uid}/profile').update({
        'name': name.trim(),
        'weightKg': weight,
        'heightCm': height,
        'age': age,
        'gender': gender,
        'targetCalories': targetCalories,
      }).catchError((e) {
        debugPrint('Error syncing profile in background: $e');
      });

      // Segera perbarui state lokal secara instan
      _userName = name.trim();
      _weightKg = weight;
      _heightCm = height;
      _age = age;
      _gender = gender;
      _targetCalories = targetCalories;
      notifyListeners();
      return null; // Sukses instan secara lokal
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return 'Gagal memperbarui profil: $e';
    }
  }

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassword,
        );
        // Re-autentikasi pengguna terlebih dahulu demi keamanan Firebase
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        return null;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return 'Password lama salah.';
        }
        return e.message ?? 'Gagal mengganti password.';
      } catch (e) {
        return 'Terjadi kesalahan: $e';
      }
    }
    return 'Sesi habis. Silakan login kembali.';
  }

  /// Cek apakah email sudah terdaftar di Realtime Database
  static Future<bool> isEmailRegistered(String email) async {
    try {
      final sanitizedEmail = email.trim().toLowerCase().replaceAll('.', '_');
      final snapshot = await _staticDb
          .ref('emails_index/$sanitizedEmail')
          .get()
          .timeout(const Duration(seconds: 4));
      return snapshot.exists;
    } catch (e) {
      debugPrint('Error checking email: $e');
      return false;
    }
  }

  /// Cek apakah sudah ada akun apapun yang tersimpan (selalu true untuk cloud)
  static Future<bool> hasAnyAccount() async {
    return true;
  }

  /// Mengirim link reset password via email menggunakan Firebase
  static Future<String?> resetPassword(String email, [String? newPassword]) async {
    if (email.isEmpty || !email.contains('@')) return 'Format email tidak valid.';
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null; // sukses mengirim link reset
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Email tidak ditemukan. Pastikan email terdaftar.';
      } else if (e.code == 'invalid-email') {
        return 'Format email tidak valid.';
      }
      return e.message ?? 'Gagal mengirim email reset password.';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  /// Hitung estimasi kalori berdasarkan profil (Harris-Benedict)
  static double estimateCalories({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    double bmr;
    if (gender == 'Laki-laki') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
    return (bmr * 1.55).roundToDouble(); // aktivitas sedang
  }
}
