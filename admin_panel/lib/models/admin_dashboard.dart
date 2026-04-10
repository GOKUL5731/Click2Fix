class AdminDashboard {
  const AdminDashboard({
    required this.totalUsers,
    required this.totalWorkers,
    required this.activeBookings,
    required this.emergencyRequests,
    required this.totalRevenue,
    required this.fraudAlerts,
    required this.workerApprovalQueue,
  });

  final int totalUsers;
  final int totalWorkers;
  final int activeBookings;
  final int emergencyRequests;
  final num totalRevenue;
  final int fraudAlerts;
  final int workerApprovalQueue;
}

