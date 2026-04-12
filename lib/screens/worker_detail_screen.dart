import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/star_rating.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class WorkerDetailScreen extends StatelessWidget {
  const WorkerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header with Avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, bottom: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 4),
                    ),
                    child: const Center(
                      child: Text('R', style: TextStyle(color: AppColors.primary, fontSize: 40, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Ravi Kumar',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: AppColors.primary, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Expert Plumber • 8 years experience', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const StarRating(rating: 4.8, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        '4.8 (127 reviews)',
                        style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Stats
                  Row(
                    children: [
                      Expanded(child: _StatBox(label: 'Trust Score', value: '92', color: AppColors.primary, icon: Icons.shield)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatBox(label: 'Distance', value: '2.4 km', color: AppColors.success, icon: Icons.location_on)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatBox(label: 'Arrival', value: '18 min', color: AppColors.accent, icon: Icons.access_time)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Quote Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quotation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        const SizedBox(height: 16),
                        _DetailRow(label: 'Estimated Price', value: '₹450', isPrice: true),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                        _DetailRow(label: 'Arrival Time', value: '18 minutes'),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                        const Text('Message from Worker', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Text(
                            '"I can fix this pipe leak in 30-45 minutes max. I have all the necessary tools."',
                            style: TextStyle(color: AppColors.textDark, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  // Reviews
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        const SizedBox(height: 20),
                        _ReviewItem(name: 'Priya S.', rating: 5, comment: 'Excellent work! Fixed my pipe in 20 minutes.'),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                        _ReviewItem(name: 'Karthik R.', rating: 4, comment: 'Good service, was slightly late but very professional.'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Book This Worker',
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      onPressed: () => context.go('/booking-confirmation'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.color, required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isPrice = false});
  final String label;
  final String value;
  final bool isPrice;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: isPrice ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isPrice ? AppColors.success : AppColors.textDark,
            ),
          ),
        ],
      );
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.name, required this.rating, required this.comment});
  final String name;
  final int rating;
  final String comment;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ],
              ),
              StarRating(rating: rating.toDouble(), size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Text(comment, style: const TextStyle(color: AppColors.textLight, fontSize: 14, height: 1.4)),
        ],
      );
}
