class WorkerRequest {
  const WorkerRequest({
    required this.id,
    required this.category,
    required this.distanceKm,
    required this.urgency,
  });

  final String id;
  final String category;
  final double distanceKm;
  final String urgency;
}

