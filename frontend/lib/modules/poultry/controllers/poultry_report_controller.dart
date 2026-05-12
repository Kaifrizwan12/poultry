import 'package:flutter/foundation.dart';
import '../models/flock_status_report_model.dart';
import '../models/demand_analysis_report_model.dart';
import '../services/poultry_report_service.dart';

class PoultryReportController extends ChangeNotifier {
  PoultryReportController() : _service = PoultryReportService();

  final PoultryReportService _service;

  FlockStatusReportModel? flockStatus;
  DemandAnalysisReportModel? demandAnalysis;
  bool isLoadingStatus  = false;
  bool isLoadingDemand  = false;
  String? errorStatus;
  String? errorDemand;

  // Tracks whether the displayed report came from cache (true) or live API.
  bool isFlockStatusOffline  = false;
  bool isDemandOffline       = false;

  String? _currentStatusFlockId;

  Future<void> loadFlockStatus(String flockId, {bool force = false}) async {
    if (!force && _currentStatusFlockId == flockId && flockStatus != null) return;
    _currentStatusFlockId = flockId;
    isLoadingStatus = true;
    errorStatus     = null;
    notifyListeners();
    try {
      flockStatus            = await _service.getFlockStatus(flockId);
      isFlockStatusOffline   = false;
    } catch (e) {
      errorStatus = e.toString();
      // If the error says "no cached report" we distinguish it in the UI via
      // isFlockStatusOffline; the error message string already contains the
      // user-friendly text from PoultryReportService.
      isFlockStatusOffline = flockStatus == null;
    }
    isLoadingStatus = false;
    notifyListeners();
  }

  Future<void> loadDemandAnalysis(List<String> flockIds, int daysAhead) async {
    isLoadingDemand = true;
    errorDemand     = null;
    notifyListeners();
    try {
      demandAnalysis   = await _service.getDemandAnalysis(flockIds, daysAhead);
      isDemandOffline  = false;
    } catch (e) {
      errorDemand     = e.toString();
      isDemandOffline = demandAnalysis == null;
    }
    isLoadingDemand = false;
    notifyListeners();
  }

  void clearStatus() {
    flockStatus           = null;
    _currentStatusFlockId = null;
    isFlockStatusOffline  = false;
    notifyListeners();
  }

  void clearDemand() {
    demandAnalysis  = null;
    isDemandOffline = false;
    notifyListeners();
  }
}
