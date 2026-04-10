class Issue {
  const Issue({
    required this.id,
    required this.description,
    required this.category,
    required this.urgency,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String description;
  final String category;
  final String urgency;
  final double latitude;
  final double longitude;
}

