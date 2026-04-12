import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/worker_card.dart';

class WorkerComparisonScreen extends StatefulWidget {
  const WorkerComparisonScreen({super.key});
  @override
  State<WorkerComparisonScreen> createState() => _WorkerComparisonState();
}

class _WorkerComparisonState extends State<WorkerComparisonScreen> {
  String _sortBy = 'rating';

  final _workers = [
    (name: 'Ravi Kumar', category: 'Plumbing', rating: 4.8, trust: 92, price: '₹450', distance: '2.4 km', eta: '18 min'),
    (name: 'Anil Raj', category: 'Plumbing', rating: 4.6, trust: 88, price: '₹520', distance: '3.1 km', eta: '12 min'),
    (name: 'Suresh M', category: 'Plumbing', rating: 4.9, trust: 95, price: '₹380', distance: '4.8 km', eta: '25 min'),
    (name: 'Kumar S', category: 'Plumbing', rating: 4.3, trust: 78, price: '₹300', distance: '1.8 km', eta: '10 min'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/ai-result'),
        ),
        title: const Text('Nearby Workers', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  '${_workers.length} found',
                  style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sort chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _SortChip(label: 'Best Rating', isActive: _sortBy == 'rating', onTap: () => setState(() => _sortBy = 'rating')),
                const SizedBox(width: 8),
                _SortChip(label: 'Lowest Price', isActive: _sortBy == 'price', onTap: () => setState(() => _sortBy = 'price')),
                const SizedBox(width: 8),
                _SortChip(label: 'Nearest', isActive: _sortBy == 'distance', onTap: () => setState(() => _sortBy = 'distance')),
                const SizedBox(width: 8),
                _SortChip(label: 'Fastest', isActive: _sortBy == 'fastest', onTap: () => setState(() => _sortBy = 'fastest')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Worker list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _workers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final w = _workers[index];
                return WorkerCard(
                  name: w.name,
                  category: w.category,
                  rating: w.rating,
                  trustScore: w.trust,
                  price: w.price,
                  distance: w.distance,
                  eta: w.eta,
                  onTap: () => context.go('/worker-detail'),
                  onBook: () => context.go('/booking-confirmation'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppColors.primary : AppColors.divider),
            boxShadow: isActive
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.textLight,
            ),
          ),
        ),
      );
}
