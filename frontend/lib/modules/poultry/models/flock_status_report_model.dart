class PendingVaccineItem {
  const PendingVaccineItem({
    required this.scheduleId,
    required this.name,
    required this.dueDate,
    required this.overdueDays,
  });

  final String scheduleId;
  final String name;
  final String dueDate;
  final int overdueDays;

  bool get isOverdue => overdueDays > 0;

  factory PendingVaccineItem.fromJson(Map<String, dynamic> json) {
    return PendingVaccineItem(
      scheduleId: '${json['scheduleId'] ?? ''}',
      name: '${json['name'] ?? ''}',
      dueDate: '${json['dueDate'] ?? ''}',
      overdueDays: (json['overdueDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class FlockStatusReportModel {
  const FlockStatusReportModel({
    required this.flock,
    required this.ageDays,
    required this.currentBirdsCount,
    required this.totalMortality,
    required this.mortalityRate,
    required this.totalFeedConsumedKg,
    required this.averageDailyFeedKg,
    required this.feedConversionRatio,
    required this.averageCurrentWeightKg,
    required this.projectedHarvestDate,
    required this.pendingVaccines,
    required this.completedVaccines,
    required this.feedHistory,
  });

  final Map<String, dynamic> flock;
  final int ageDays;
  final int currentBirdsCount;
  final int totalMortality;
  final String mortalityRate;
  final double totalFeedConsumedKg;
  final double averageDailyFeedKg;
  final double feedConversionRatio;
  final double averageCurrentWeightKg;
  final String? projectedHarvestDate;
  final List<PendingVaccineItem> pendingVaccines;
  final List<Map<String, dynamic>> completedVaccines;
  final List<Map<String, dynamic>> feedHistory;

  factory FlockStatusReportModel.fromJson(Map<String, dynamic> json) {
    return FlockStatusReportModel(
      flock: Map<String, dynamic>.from(json['flock'] as Map? ?? {}),
      ageDays: (json['ageDays'] as num?)?.toInt() ?? 0,
      currentBirdsCount: (json['currentBirdsCount'] as num?)?.toInt() ?? 0,
      totalMortality: (json['totalMortality'] as num?)?.toInt() ?? 0,
      mortalityRate: '${json['mortalityRate'] ?? '0%'}',
      totalFeedConsumedKg: (json['totalFeedConsumedKg'] as num?)?.toDouble() ?? 0,
      averageDailyFeedKg: (json['averageDailyFeedKg'] as num?)?.toDouble() ?? 0,
      feedConversionRatio: (json['feedConversionRatio'] as num?)?.toDouble() ?? 0,
      averageCurrentWeightKg: (json['averageCurrentWeightKg'] as num?)?.toDouble() ?? 0,
      projectedHarvestDate: json['projectedHarvestDate'] as String?,
      pendingVaccines: ((json['pendingVaccines'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => PendingVaccineItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      completedVaccines: ((json['completedVaccines'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(),
      feedHistory: ((json['feedHistory'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(),
    );
  }
}
