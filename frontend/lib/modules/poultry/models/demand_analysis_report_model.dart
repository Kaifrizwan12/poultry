class ProjectedFeedItem {
  const ProjectedFeedItem({
    required this.date,
    required this.ageDays,
    required this.scheduleName,
    required this.productId,
    required this.productName,
    required this.requiredKg,
    required this.requiredBags,
  });

  final String date;
  final int ageDays;
  final String scheduleName;
  final String productId;
  final String productName;
  final double requiredKg;
  final double requiredBags;

  factory ProjectedFeedItem.fromJson(Map<String, dynamic> json) {
    return ProjectedFeedItem(
      date: '${json['date'] ?? ''}',
      ageDays: (json['ageDays'] as num?)?.toInt() ?? 0,
      scheduleName: '${json['scheduleName'] ?? ''}',
      productId: '${json['productId'] ?? ''}',
      productName: '${json['productName'] ?? ''}',
      requiredKg: (json['requiredKg'] as num?)?.toDouble() ?? 0,
      requiredBags: (json['requiredBags'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProjectedVaccineItem {
  const ProjectedVaccineItem({
    required this.date,
    required this.scheduleName,
    required this.productId,
    required this.productName,
    required this.birdsCount,
    required this.totalDose,
  });

  final String date;
  final String scheduleName;
  final String productId;
  final String productName;
  final int birdsCount;
  final double totalDose;

  factory ProjectedVaccineItem.fromJson(Map<String, dynamic> json) {
    return ProjectedVaccineItem(
      date: '${json['date'] ?? ''}',
      scheduleName: '${json['scheduleName'] ?? ''}',
      productId: '${json['productId'] ?? ''}',
      productName: '${json['productName'] ?? ''}',
      birdsCount: (json['birdsCount'] as num?)?.toInt() ?? 0,
      totalDose: (json['totalDose'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FlockDemandResult {
  const FlockDemandResult({
    required this.flockId,
    required this.flockName,
    required this.projectedFeed,
    required this.projectedVaccines,
  });

  final String flockId;
  final String flockName;
  final List<ProjectedFeedItem> projectedFeed;
  final List<ProjectedVaccineItem> projectedVaccines;

  factory FlockDemandResult.fromJson(Map<String, dynamic> json) {
    return FlockDemandResult(
      flockId: '${json['flockId'] ?? ''}',
      flockName: '${json['flockName'] ?? ''}',
      projectedFeed: ((json['projectedFeed'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => ProjectedFeedItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      projectedVaccines: ((json['projectedVaccines'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => ProjectedVaccineItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class AggregatedFeedProduct {
  const AggregatedFeedProduct({required this.productId, required this.productName, required this.totalKg});
  final String productId;
  final String productName;
  final double totalKg;
  factory AggregatedFeedProduct.fromJson(Map<String, dynamic> json) => AggregatedFeedProduct(
    productId: '${json['productId'] ?? ''}',
    productName: '${json['productName'] ?? ''}',
    totalKg: (json['totalKg'] as num?)?.toDouble() ?? 0,
  );
}

class AggregatedVaccineProduct {
  const AggregatedVaccineProduct({required this.productId, required this.productName, required this.totalDose});
  final String productId;
  final String productName;
  final double totalDose;
  factory AggregatedVaccineProduct.fromJson(Map<String, dynamic> json) => AggregatedVaccineProduct(
    productId: '${json['productId'] ?? ''}',
    productName: '${json['productName'] ?? ''}',
    totalDose: (json['totalDose'] as num?)?.toDouble() ?? 0,
  );
}

class DemandAnalysisReportModel {
  const DemandAnalysisReportModel({
    required this.asOfDate,
    required this.projectionDays,
    required this.flocks,
    required this.aggregatedFeed,
    required this.aggregatedVaccines,
  });

  final String asOfDate;
  final int projectionDays;
  final List<FlockDemandResult> flocks;
  final List<AggregatedFeedProduct> aggregatedFeed;
  final List<AggregatedVaccineProduct> aggregatedVaccines;

  factory DemandAnalysisReportModel.fromJson(Map<String, dynamic> json) {
    final aggregated = json['aggregated'] as Map? ?? {};
    return DemandAnalysisReportModel(
      asOfDate: '${json['asOfDate'] ?? ''}',
      projectionDays: (json['projectionDays'] as num?)?.toInt() ?? 7,
      flocks: ((json['flocks'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => FlockDemandResult.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      aggregatedFeed: ((aggregated['feedByProduct'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => AggregatedFeedProduct.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      aggregatedVaccines: ((aggregated['vaccineByProduct'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => AggregatedVaccineProduct.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}
