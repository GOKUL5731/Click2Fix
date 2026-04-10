import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/star_rating.dart';
import '../widgets/primary_action_button.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() { _commentController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          Container(
            width: 80, height: 80, decoration: BoxDecoration(color: AppColors.successGreen.withAlpha(20), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.check_circle, size: 42, color: AppColors.successGreen),
          ),
          const SizedBox(height: 16),
          Text('Service Completed! 🎉', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('How was your experience with Ravi Kumar?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          StarRating(rating: _rating, size: 40, onChanged: (v) => setState(() => _rating = v)),
          const SizedBox(height: 8),
          Text(_rating == 0 ? 'Tap to rate' : _rating >= 4 ? 'Excellent! 🌟' : _rating >= 3 ? 'Good 👍' : 'We\'ll improve 💪',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          TextField(
            controller: _commentController, maxLines: 4,
            decoration: const InputDecoration(hintText: 'Write a review (optional)...', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _QuickTag(label: '⚡ Fast service', onTap: () => _commentController.text += 'Fast service. '),
            _QuickTag(label: '👨‍🔧 Professional', onTap: () => _commentController.text += 'Very professional. '),
            _QuickTag(label: '💰 Fair price', onTap: () => _commentController.text += 'Fair pricing. '),
            _QuickTag(label: '🧹 Clean work', onTap: () => _commentController.text += 'Left the area clean. '),
          ]),
          const SizedBox(height: 32),
          PrimaryActionButton(label: 'Submit Review', icon: Icons.send, onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your review! 🙏')));
            context.go('/home');
          }),
          const SizedBox(height: 12),
          TextButton(onPressed: () => context.go('/home'), child: const Text('Skip')),
        ]),
      ),
    );
  }
}

class _QuickTag extends StatelessWidget {
  const _QuickTag({required this.label, required this.onTap});
  final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(10), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryBlue.withAlpha(30))),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    ),
  );
}
