import 'package:farm_mgt_auth/core/app_exception.dart';
import 'package:farm_mgt_auth/services/api_service.dart';
import 'package:farm_mgt_auth/services/offline_cache_service.dart';
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

  // ── Flock status report ───────────────────────────────────────────────────────

  Future<FlockStatusReportModel> getFlockStatus(String flockId) async {
    const path     = '/poultry/reports/flock-status';
    final cacheKey = OfflineCacheService.poultryReportKey('flock_status', flockId);
    _log('GET $path?flockId=$flockId');
    try {
      final response = await _api.get('$path?flockId=$flockId', auth: true);
      if (response['success'] != true) {
        throw AppException('${response['error'] ?? 'Failed to load report'}');
      }
      final data = Map<String, dynamic>.from(response['data'] as Map? ?? {});
      // Cache the raw JSON so it can be replayed offline.
      await OfflineCacheService.saveItem(cacheKey, data);
      _log('GET $path → report cached for flock $flockId');
      return FlockStatusReportModel.fromJson(data);
    } on NetworkException {
      final cached = OfflineCacheService.readItem(cacheKey);
      if (cached != null) {
        _log('GET $path → cache hit (offline)');
        return FlockStatusReportModel.fromJson(cached);
      }
      throw AppException(
          'No internet and no cached flock-status report for flock $flockId.');
    } catch (e) {
      _log('GET $path', error: e);
      rethrow;
    }
  }

  // ── Demand analysis report ────────────────────────────────────────────────────

  Future<DemandAnalysisReportModel> getDemandAnalysis(
    List<String> flockIds,
    int daysAhead,
  ) async {
    const path = '/poultry/reports/demand-analysis';
    // Use a stable hash of the parameters as the cache key suffix.
    final paramHash = (flockIds.join(',') + ':$daysAhead').hashCode.abs().toString();
    final cacheKey  = OfflineCacheService.poultryReportKey('demand_analysis', paramHash);
    _log('GET $path flockIds=$flockIds daysAhead=$daysAhead');
    try {
      final qs       = flockIds.map((id) => 'flockIds[]=$id').join('&');
      final response = await _api.get('$path?$qs&daysAhead=$daysAhead', auth: true);
      if (response['success'] != true) {
        throw AppException('${response['error'] ?? 'Failed to load report'}');
      }
      final data = Map<String, dynamic>.from(response['data'] as Map? ?? {});
      await OfflineCacheService.saveItem(cacheKey, data);
      _log('GET $path → demand analysis cached');
      return DemandAnalysisReportModel.fromJson(data);
    } on NetworkException {
      final cached = OfflineCacheService.readItem(cacheKey);
      if (cached != null) {
        _log('GET $path → cache hit (offline)');
        return DemandAnalysisReportModel.fromJson(cached);
      }
      throw AppException(
          'No internet and no cached demand-analysis report available.');
    } catch (e) {
      _log('GET $path', error: e);
      rethrow;
    }
  }
}
