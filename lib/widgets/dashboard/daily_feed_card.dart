import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/booking_model.dart';
import '../../providers/dog_provider.dart';

class DailyFeedCard extends StatelessWidget {
  final List<Booking> checkIns;
  final List<Booking> checkOuts;

  const DailyFeedCard({
    super.key,
    required this.checkIns,
    required this.checkOuts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FeedColumn(
                title: AppStrings.todayCheckIns,
                bookings: checkIns,
                icon: Icons.login,
                color: AppColors.primary,
              ),
            ),
            const VerticalDivider(width: 24),
            Expanded(
              child: _FeedColumn(
                title: AppStrings.todayCheckOuts,
                bookings: checkOuts,
                icon: Icons.logout,
                color: AppColors.statusCompleted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedColumn extends StatelessWidget {
  final String title;
  final List<Booking> bookings;
  final IconData icon;
  final Color color;

  const _FeedColumn({
    required this.title,
    required this.bookings,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dogs = context.watch<DogProvider>().dogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (bookings.isEmpty)
          Text(
            AppStrings.noBookings,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          )
        else
          ...bookings.map((b) {
            final names = b.dogIds
                .map((id) => dogs.firstWhere(
                      (d) => d.id == id,
                      orElse: () => dogs.first,
                    ).name)
                .where((n) => n.isNotEmpty)
                .join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                names.isNotEmpty ? names : b.id,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
      ],
    );
  }
}
