import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/booking_model.dart';
import '../../providers/dog_provider.dart';

class IntroRemindersCard extends StatelessWidget {
  final List<Booking> intros;

  const IntroRemindersCard({super.key, required this.intros});

  @override
  Widget build(BuildContext context) {
    if (intros.isEmpty) return const SizedBox.shrink();

    final dogs = context.watch<DogProvider>().dogs;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handshake_outlined,
                    size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  AppStrings.todayIntros,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...intros.map((b) {
              final names = b.dogIds
                  .map((id) {
                    final idx = dogs.indexWhere((d) => d.id == id);
                    return idx != -1 ? dogs[idx].name : '';
                  })
                  .where((n) => n.isNotEmpty)
                  .join(', ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (b.meetingTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b.meetingTime!,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        names.isNotEmpty ? names : b.id,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
