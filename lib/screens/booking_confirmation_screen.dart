import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/workers'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.receipt_long, size: 40, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirm Booking',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review your booking details',
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
            ),
            const SizedBox(height: 32),
            
            // Summary Card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 20),
                  _SumRow(label: 'Issue', value: 'Pipe Leakage'),
                  const SizedBox(height: 12),
                  _SumRow(label: 'Category', value: 'Plumbing'),
                  const SizedBox(height: 12),
                  _SumRow(label: 'Urgency', value: 'High'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                  _SumRow(label: 'Worker', value: 'Ravi Kumar ✓'),
                  const SizedBox(height: 12),
                  _SumRow(label: 'Rating', value: '4.8 ★'),
                  const SizedBox(height: 12),
                  _SumRow(label: 'ETA', value: '18 minutes'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                  _SumRow(label: 'Service Fee', value: '₹450'),
                  const SizedBox(height: 12),
                  _SumRow(label: 'Platform Fee', value: '₹45'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: const [
                        Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                        Spacer(),
                        Text('₹495', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Location
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on, color: AppColors.success),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Service Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                        SizedBox(height: 4),
                        Text('Chennai, Tamil Nadu • GPS confirmed', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Confirm & Book',
                icon: const Icon(Icons.check_circle, color: Colors.white),
                onPressed: () => context.go('/tracking'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Go Back',
                isOutlined: true,
                onPressed: () => context.go('/workers'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow({required this.label, required this.value});
  final String label;
  final String value;
  
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textDark)),
        ],
      );
}
