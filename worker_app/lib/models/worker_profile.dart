class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.name,
    required this.trustScore,
    required this.rating,
    required this.available,
  });

  final String id;
  final String name;
  final double trustScore;
  final double rating;
  final bool available;
}

