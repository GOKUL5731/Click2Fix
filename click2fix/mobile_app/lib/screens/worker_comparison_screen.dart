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
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/ai-result')),
        title: const Text('Nearby Workers'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.people, size: 14, color: AppColors.successGreen),
              const SizedBox(width: 4),
              Text('${_workers.length} found', style: const TextStyle(fontSize: 12, color: AppColors.successGreen, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sort chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _SortChip(label: 'Best Rating', isActive: _sortBy == 'rating', onTap: () => setState(() => _sortBy = 'rating')),
              const SizedBox(width: 8),
              _SortChip(label: 'Lowest Price', isActive: _sortBy == 'price', onTap: () => setState(() => _sortBy = 'price')),
              const SizedBox(width: 8),
              _SortChip(label: 'Nearest', isActive: _sortBy == 'distance', onTap: () => setState(() => _sortBy = 'distance')),
              const SizedBox(width: 8),
              _SortChip(label: 'Fastest', isActive: _sortBy == 'fastest', onTap: () => setState(() => _sortBy = 'fastest')),
            ]),
          ),
          // Worker list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _workers.length,
              itemBuilder: (context, index) {
                final w = _workers[index];
                return WorkerCard(
                  name: w.name, category: w.category, rating: w.rating, trustScore: w.trust,
                  price: w.price, distance: w.distance, eta: w.eta,
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
  final String label; final bool isActive; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppColors.primaryBlue : AppColors.divider),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? Colors.white : AppColors.textSecondary)),
    ),
  );
}
