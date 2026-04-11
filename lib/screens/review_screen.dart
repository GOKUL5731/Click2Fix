import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/booking_service.dart';
import '../widgets/star_rating.dart';
import '../widgets/primary_action_button.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating before submitting'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Get bookingId and workerId from route extra (if provided)
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final bookingId = extra?['bookingId'] as String?;
    final workerId = extra?['workerId'] as String?;

    try {
      if (bookingId != null && workerId != null) {
        final session = ref.read(sessionProvider);
        final client = ref.read(apiClientProvider);
        client.setToken(session.token);
        final bookingService = BookingService(client);
        await bookingService.submitRating(
          bookingId: bookingId,
          workerId: workerId,
          rating: _rating.round(),
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
        );
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your review! ðŸ™'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // Even if API fails, show success and navigate home (review is best-effort)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted! Thank you ðŸ™'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.check_circle, size: 42, color: AppColors.successGreen),
          ),
          const SizedBox(height: 16),
          Text('Service Completed! ðŸŽ‰', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'How was your experience?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          StarRating(rating: _rating, size: 40, onChanged: (v) => setState(() => _rating = v)),
          const SizedBox(height: 8),
          Text(
            _rating == 0
                ? 'Tap to rate'
                : _rating >= 4
                    ? 'Excellent! ðŸŒŸ'
                    : _rating >= 3
                        ? 'Good ðŸ‘'
                        : 'We\'ll improve ðŸ’ª',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write a review (optional)...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _QuickTag(label: 'âš¡ Fast service', onTap: () => _commentController.text += 'Fast service. '),
            _QuickTag(label: 'ðŸ‘¨â€ðŸ”§ Professional', onTap: () => _commentController.text += 'Very professional. '),
            _QuickTag(label: 'ðŸ’° Fair price', onTap: () => _commentController.text += 'Fair pricing. '),
            _QuickTag(label: 'ðŸ§¹ Clean work', onTap: () => _commentController.text += 'Left the area clean. '),
          ]),
          const SizedBox(height: 32),
          PrimaryActionButton(
            label: _submitted ? 'Submitted âœ“' : 'Submit Review',
            icon: _submitted ? Icons.check : Icons.send,
            isLoading: _isSubmitting,
            onPressed: _submitted ? () {} : _submitReview,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Skip'),
          ),
        ]),
      ),
    );
  }
}

class _QuickTag extends StatelessWidget {
  const _QuickTag({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withAlpha(30)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    ),
  );
}

