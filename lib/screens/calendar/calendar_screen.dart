import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/bookings/booking_card.dart';
import '../bookings/booking_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final selectedBookings = provider.getBookingsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.calendar)),
      body: Column(
        children: [
          TableCalendar<Booking>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: provider.getBookingsForDay,
            locale: 'he_IL',
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 2,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;

                final hasBoarding = events
                    .any((e) => e.type == BookingType.boarding);
                final hasIntro = events
                    .any((e) => e.type == BookingType.introMeeting);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasBoarding)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: AppColors.boardingDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasIntro)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: AppColors.introMeetingDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                );
              },
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedBookings.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.noBookings,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: selectedBookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        BookingCard(booking: selectedBookings[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingFormScreen(initialDate: _selectedDay),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
