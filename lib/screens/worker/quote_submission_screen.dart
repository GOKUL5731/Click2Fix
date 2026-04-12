import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../widgets/primary_action_button.dart';

class QuoteSubmissionScreen extends StatefulWidget {
  const QuoteSubmissionScreen({super.key});
  @override
  State<QuoteSubmissionScreen> createState() => _QuoteState();
}

class _QuoteState extends State<QuoteSubmissionScreen> {
  final _priceController = TextEditingController(text: '450');
  final _msgController = TextEditingController(text: 'I can fix this within 30-45 minutes.');
  String _eta = '15-20 min';
  bool _isSending = false;

  @override
  void dispose() { _priceController.dispose(); _msgController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/worker/dashboard')),
        title: const Text('Send Quotation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Issue summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.plumbing, color: AppColors.primaryBlue, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kitchen Pipe Leaking', style: Theme.of(context).textTheme.titleSmall),
                Text('T. Nagar, Chennai • 2.4 km away', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.emergencyRed.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                child: const Text('High', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.emergencyRed))),
            ]),
          ),
          const SizedBox(height: 24),
          Text('Your Quote', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(controller: _priceController, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price (₹)', prefixIcon: Icon(Icons.currency_rupee))),
          const SizedBox(height: 14),
          Text('Arrival Time', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(children: [
            _EtaChip(label: '10-15 min', isActive: _eta == '10-15 min', onTap: () => setState(() => _eta = '10-15 min')),
            const SizedBox(width: 8),
            _EtaChip(label: '15-20 min', isActive: _eta == '15-20 min', onTap: () => setState(() => _eta = '15-20 min')),
            const SizedBox(width: 8),
            _EtaChip(label: '20-30 min', isActive: _eta == '20-30 min', onTap: () => setState(() => _eta = '20-30 min')),
          ]),
          const SizedBox(height: 18),
          TextField(controller: _msgController, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Message to customer', hintText: 'Describe your approach...')),
          const SizedBox(height: 28),
          PrimaryActionButton(
            label: 'Send Quotation', icon: Icons.send, isLoading: _isSending,
            onPressed: () {
              setState(() => _isSending = true);
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (!mounted) return;
                setState(() => _isSending = false);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quote sent successfully!')),
                );
                context.go('/worker/dashboard');
              });
            },
          ),
        ]),
      ),
    );
  }
}

class _EtaChip extends StatelessWidget {
  const _EtaChip({required this.label, required this.isActive, required this.onTap});
  final String label; final bool isActive; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: isActive ? AppColors.primaryBlue : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? AppColors.primaryBlue : AppColors.divider)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? Colors.white : AppColors.textSecondary)),
    ),
  );
}
