import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/primary_action_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'upi';
  bool _isProcessing = false;

  void _pay() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) { setState(() => _isProcessing = false); context.go('/review'); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Amount
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Text('Total Amount', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('â‚¹495', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Including â‚¹45 platform fee', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
            ]),
          ),
          const SizedBox(height: 24),
          Text('Payment Method', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _PayMethod(icon: Icons.account_balance, label: 'UPI', sub: 'Google Pay, PhonePe, Paytm', isActive: _method == 'upi', onTap: () => setState(() => _method = 'upi')),
          const SizedBox(height: 8),
          _PayMethod(icon: Icons.credit_card, label: 'Card', sub: 'Debit / Credit Card', isActive: _method == 'card', onTap: () => setState(() => _method = 'card')),
          const SizedBox(height: 8),
          _PayMethod(icon: Icons.money, label: 'Cash', sub: 'Pay after service', isActive: _method == 'cash', onTap: () => setState(() => _method = 'cash')),
          const SizedBox(height: 28),
          PrimaryActionButton(label: 'Pay â‚¹495', icon: Icons.lock, isLoading: _isProcessing, onPressed: _pay),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.shield_outlined, size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            Text('Secure payment â€¢ SSL encrypted', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
          ]),
        ]),
      ),
    );
  }
}

class _PayMethod extends StatelessWidget {
  const _PayMethod({required this.icon, required this.label, required this.sub, required this.isActive, required this.onTap});
  final IconData icon; final String label; final String sub; final bool isActive; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? AppColors.primaryBlue : (isDark ? Colors.white10 : AppColors.divider), width: isActive ? 2 : 1),
        ),
        child: Row(children: [
          Icon(icon, color: isActive ? AppColors.primaryBlue : AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Text(sub, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ])),
          if (isActive) const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 22),
        ]),
      ),
    );
  }
}


