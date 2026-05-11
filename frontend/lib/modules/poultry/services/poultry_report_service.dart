import 'package:farm_mgt_auth/core/app_exception.dart';
import 'package:farm_mgt_auth/services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/flock_status_report_model.dart';
import '../models/demand_analysis_report_model.dart';

class PoultryReportService {
  PoultryReportService() : _api = ApiService();

  final ApiService _api;

  static void _log(String message, {Object? error}) {
    if (!kDebugMode) return;
    final ts = DateTime.now().toIso8601String();
    debugPrint(error != null
        ? '[$ts] [POULTRY:REPORT] ERROR $message — $error'
        : '[$ts] [POULTRY:REPORT] $message');
  }

  Future<FlockStatusReportModel> getFlockStatus(String flockId) async {
    const path = '/poultry/reports/flock-status';
    _log('GET $path?flockId=$flockId');
    try {
      final response = await _api.get('$path?flockId=$flockId', auth: true);
      if (response['success'] != true) {
        throw AppException('${response['error'] ?? 'Failed to load report'}');
      }
      _log('GET $path → report generated for flock $flockId');
      return FlockStatusReportModel.fromJson(
          Map<String, dynamic>.from(response['data'] as Map? ?? {}));
    } catch (e) {
      _log('GET $path', error: e);
      rethrow;
    }
  }

  Future<DemandAnalysisReportModel> getDemandAnalysis(
    List<String> flockIds,
    int daysAhead,
  ) async {
    const path = '/poultry/reports/demand-analysis';
    _log('GET $path flockIds=$flockIds daysAhead=$daysAhead');
    try {
      final qs = flockIds.map((id) => 'flockIds[]=$id').join('&');
      final response = await _api.get('$path?$qs&daysAhead=$daysAhead', auth: true);
      if (response['success'] != true) {
        throw AppException('${response['error'] ?? 'Failed to load report'}');
      }
      _log('GET $path → demand analysis generated');
      return DemandAnalysisReportModel.fromJson(
          Map<String, dynamic>.from(response['data'] as Map? ?? {}));
    } catch (e) {
      _log('GET $path', error: e);
      rethrow;
    }
  }
}
