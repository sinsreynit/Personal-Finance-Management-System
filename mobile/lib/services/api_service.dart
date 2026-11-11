import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../models/saving_goal.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  ApiException(this.statusCode, this.message, [this.errors]);
  @override
  String toString() => message;
}

class ApiService {
  static const _tokenKey = 'auth_token';

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
  Map<String, String>? cleanQuery;
  if (query != null) {
    cleanQuery = query.map((k, v) => MapEntry(k, v.toString()));
    cleanQuery.removeWhere((k, v) => v == 'null');
  }
  return Uri.parse('$kApiBaseUrl$path').replace(queryParameters: cleanQuery);
}

  dynamic _handle(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(
      res.statusCode,
      body?['message'] ?? 'Something went wrong (${res.statusCode})',
      body?['errors'],
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final res = await http.get(_uri(path, query), headers: await _headers(auth: auth));
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> data, {bool auth = true}) async {
    final res = await http.post(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(data));
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> data, {bool auth = true}) async {
    final res = await http.put(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(data));
    return _handle(res);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final res = await http.delete(_uri(path), headers: await _headers(auth: auth));
    return _handle(res);
  }

  Future<List<Budget>> getBudgets() async {
  final data = await get('/budgets');
  return (data as List).map((e) => Budget.fromJson(e)).toList();
  }

  Future<Budget> createBudget(Map<String, dynamic> payload) async {
  final data = await post('/budgets', payload);
  return Budget.fromJson(data);
  }

  Future<Budget> updateBudget(int id, Map<String, dynamic> payload) async {
  final data = await put('/budgets/$id', payload);
  return Budget.fromJson(data);
  }

  Future<void> deleteBudget(int id) async {
  await delete('/budgets/$id');
  }

  Future<Map<String, dynamic>> monitorBudget(int id) async {
    return await get('/budgets/$id/monitor');
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
  final data = await get('/savings-goals');
  return (data as List).map((e) => SavingsGoal.fromJson(e)).toList();
  }

  Future<SavingsGoal> createSavingsGoal(
    Map<String, dynamic> payload,
  ) async {
    final data = await post('/savings-goals', payload);
    return SavingsGoal.fromJson(data);
  }

  Future<SavingsGoal> updateSavingsGoal(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final data = await put('/savings-goals/$id', payload);
    return SavingsGoal.fromJson(data);
  }

  Future<Map<String, dynamic>> addSavingsProgress(
    int id,
    double amount,
  ) async {
    final data = await post(
      '/savings-goals/$id/progress',
      {'amount': amount},
    );

    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> deleteSavingsGoal(int id) async {
    await delete('/savings-goals/$id');
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
  return await get('/dashboard/summary');
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
  return await post('/login', {'email': email, 'password': password}, auth: false);
  }

  Future<void> logout() async {
  await post('/logout', {});
  }


  Future<Map<String, dynamic>> getProfile() async {
  return await get('/profile');
  }

  Future<Map<String, dynamic>> updateProfile(String name, String email) async {
  return await put('/profile', {'name': name, 'email': email});
  }

  Future<Map<String, dynamic>> getFinancialReport({DateTime? from, DateTime? to}) async {
    return await get('/reports/financial', query: {
      if (from != null) 'from': from.toIso8601String().split('T').first,
      if (to != null) 'to': to.toIso8601String().split('T').first,
    });
  }

  Future<Map<String, dynamic>> getIncomeReport({DateTime? from, DateTime? to}) async {
    return await get('/reports/income', query: {
      if (from != null) 'from': from.toIso8601String().split('T').first,
      if (to != null) 'to': to.toIso8601String().split('T').first,
    });
  }

  Future<Map<String, dynamic>> getExpenseReport({DateTime? from, DateTime? to}) async {
    return await get('/reports/expense', query: {
      if (from != null) 'from': from.toIso8601String().split('T').first,
      if (to != null) 'to': to.toIso8601String().split('T').first,
    });
  }

  Future<Map<String, dynamic>> getBudgetReport({DateTime? from, DateTime? to}) async {
    return await get('/reports/budget', query: {
      if (from != null) 'from': from.toIso8601String().split('T').first,
      if (to != null) 'to': to.toIso8601String().split('T').first,
    });
  }

  Future<Map<String, dynamic>> getChartData({DateTime? from, DateTime? to}) async {
    return await get('/reports/chart-data', query: {
      if (from != null) 'from': from.toIso8601String().split('T').first,
      if (to != null) 'to': to.toIso8601String().split('T').first,
    });
  }

  /// Downloads the PDF report as raw bytes. This bypasses [_handle] because
  /// the response body is a binary PDF, not JSON.
  Future<List<int>> exportReportPdf({DateTime? from, DateTime? to}) async {
    final uri = _uri('/reports/export/pdf', {
      if (from != null) 'from': from.toIso8601String().split('T').first,
      if (to != null) 'to': to.toIso8601String().split('T').first,
    });
    final res = await http.get(uri, headers: await _headers(auth: true));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes;
    }
    throw ApiException(res.statusCode, 'Could not export PDF (${res.statusCode}).');
  }
}
