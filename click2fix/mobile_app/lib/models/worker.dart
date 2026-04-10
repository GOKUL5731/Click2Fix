class WorkerSummary {
  const WorkerSummary({
    required this.id,
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.arrivalMinutes,
    required this.price,
    required this.trustScore,
  });

  final String id;
  final String name;
  final double rating;
  final double distanceKm;
  final int arrivalMinutes;
  final int price;
  final double trustScore;
}

