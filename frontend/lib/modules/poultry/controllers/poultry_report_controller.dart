import 'package:flutter/foundation.dart';
import '../models/flock_status_report_model.dart';
import '../models/demand_analysis_report_model.dart';
import '../services/poultry_report_service.dart';

class PoultryReportController extends ChangeNotifier {
  PoultryReportController() : _service = PoultryReportService();

  final PoultryReportService _service;

  FlockStatusReportModel? flockStatus;
  DemandAnalysisReportModel? demandAnalysis;
  bool isLoadingStatus = false;
  bool isLoadingDemand = false;
  String? errorStatus;
  String? errorDemand;
  String? _currentStatusFlockId;

  Future<void> loadFlockStatus(String flockId, {bool force = false}) async {
    if (!force && _currentStatusFlockId == flockId && flockStatus != null) return;
    _currentStatusFlockId = flockId;
    isLoadingStatus = true;
    errorStatus = null;
    notifyListeners();
    try {
      flockStatus = await _service.getFlockStatus(flockId);
    } catch (e) {
      errorStatus = e.toString();
    }
    isLoadingStatus = false;
    notifyListeners();
  }

  Future<void> loadDemandAnalysis(List<String> flockIds, int daysAhead) async {
    isLoadingDemand = true;
    errorDemand = null;
    notifyListeners();
    try {
      demandAnalysis = await _service.getDemandAnalysis(flockIds, daysAhead);
    } catch (e) {
      errorDemand = e.toString();
    }
    isLoadingDemand = false;
    notifyListeners();
  }

  void clearStatus() {
    flockStatus = null;
    _currentStatusFlockId = null;
    notifyListeners();
  }

  void clearDemand() {
    demandAnalysis = null;
    notifyListeners();
  }
}
