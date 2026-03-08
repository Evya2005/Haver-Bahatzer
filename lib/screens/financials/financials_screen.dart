import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/booking_model.dart';
import '../../models/dog_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/dog_provider.dart';

class FinancialsScreen extends StatefulWidget {
  const FinancialsScreen({super.key});

  @override
  State<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends State<FinancialsScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showIncomeDetails(
    BuildContext context,
    List<Booking> bookings,
    DogProvider dogProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _IncomeDetailsSheet(
        bookings: bookings,
        dogProvider: dogProvider,
      ),
    );
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final dogProvider = context.watch<DogProvider>();

    final monthRevenue = bookingProvider.revenueForMonth(_selectedMonth);
    final avgStay = bookingProvider.averageStayDaysForMonth(_selectedMonth);
    final dogsHosted = bookingProvider.uniqueDogsHostedForMonth(_selectedMonth);
    final dayDist = bookingProvider.bookingDayDistributionForMonth(_selectedMonth);
    final unpaid = bookingProvider.unpaidBookings;
    final monthFormat = DateFormat('MMMM yyyy', 'he');
    final dateFormat = DateFormat('dd/MM/yyyy', 'he');

    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);

    // ── Month picker (shared between both tabs) ────────────────────────────
    final monthPicker = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month - 1,
              );
            }),
          ),
          Text(
            monthFormat.format(_selectedMonth),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isCurrentMonth
                ? null
                : () => setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      );
                    }),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.financials),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'סטטיסטיקה'),
            Tab(text: 'הזמנות'),
          ],
        ),
      ),
      body: Column(
        children: [
          monthPicker,
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 0: Statistics ──────────────────────────────────────
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    // ── Widget 1: Monthly Income ───────────────────────────
                    _StatCard(
                      icon: Icons.payments_outlined,
                      label: 'הכנסות חודשיות',
                      value: '₪${monthRevenue.toStringAsFixed(0)}',
                      onTap: () => _showIncomeDetails(
                        context,
                        bookingProvider.paidBookingsForMonth(_selectedMonth),
                        dogProvider,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Widget 2: Average Stay Days ────────────────────────
                    _StatCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'ממוצע ימי שהייה',
                      value: avgStay.toStringAsFixed(1),
                    ),
                    const SizedBox(height: 12),

                    // ── Widget 3: Dogs Hosted ──────────────────────────────
                    _StatCard(
                      icon: Icons.pets_outlined,
                      label: 'כלבים שאורחו',
                      value: '$dogsHosted',
                    ),
                    const SizedBox(height: 12),

                    // ── Widget 4: Day-of-Week Distribution ─────────────────
                    _DayDistributionCard(distribution: dayDist),

                    const SizedBox(height: 24),

                    // ── Debt Tracker ───────────────────────────────────────
                    Text(AppStrings.debtTracker, style: titleStyle),
                    const SizedBox(height: 8),
                    if (unpaid.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          AppStrings.noUnpaid,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ...unpaid.map((b) => _DebtCard(
                            booking: b,
                            dogs: dogProvider.dogs,
                            dateFormat: dateFormat,
                          )),

                    const SizedBox(height: 24),
                  ],
                ),

                // ── Tab 1: Bookings Table ──────────────────────────────────
                _BookingsTableTab(
                  selectedMonth: _selectedMonth,
                  bookingProvider: bookingProvider,
                  dogProvider: dogProvider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bookings Table Tab ───────────────────────────────────────────────────────

class _BookingsTableTab extends StatelessWidget {
  final DateTime selectedMonth;
  final BookingProvider bookingProvider;
  final DogProvider dogProvider;

  const _BookingsTableTab({
    required this.selectedMonth,
    required this.bookingProvider,
    required this.dogProvider,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yy', 'he');
    final bookings = bookingProvider.boardingBookingsForMonth(selectedMonth)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          'אין הזמנות לחודש זה',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    const headerStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    Widget headerRow() => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              const Expanded(flex: 3, child: Text('שם בעלים', style: headerStyle)),
              const Expanded(flex: 2, child: Text('עלות', style: headerStyle)),
              const Expanded(flex: 2, child: Text('אמצעי תשלום', style: headerStyle)),
              SizedBox(
                width: 60,
                child: const Text('תאריך תשלום', style: headerStyle, textAlign: TextAlign.end),
              ),
            ],
          ),
        );

    return Column(
      children: [
        headerRow(),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = bookings[i];
              final ownerName = b.dogIds
                  .map((id) {
                    final idx = dogProvider.dogs.indexWhere((d) => d.id == id);
                    return idx != -1 ? dogProvider.dogs[idx].ownerName : '';
                  })
                  .where((n) => n.isNotEmpty)
                  .toSet()
                  .join(', ');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        ownerName.isNotEmpty ? ownerName : '—',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₪${b.totalPrice?.toStringAsFixed(0) ?? '—'}',
                        style: TextStyle(
                          color: b.isPaid ? AppColors.primary : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        b.paymentMethod?.hebrewLabel ?? '—',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        b.paidAt != null ? dateFormat.format(b.paidAt!) : '—',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Day Distribution Card ────────────────────────────────────────────────────

class _DayDistributionCard extends StatelessWidget {
  final List<double> distribution;

  const _DayDistributionCard({required this.distribution});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'התפלגות ימי הזמנה',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final fraction = i < distribution.length ? distribution[i] : 0.0;
                return _DayBar(
                  fraction: fraction,
                  label: dayLabels[i],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final double fraction;
  final String label;

  const _DayBar({required this.fraction, required this.label});

  @override
  Widget build(BuildContext context) {
    const maxBarHeight = 80.0;
    final barHeight = (fraction * maxBarHeight).clamp(2.0, maxBarHeight);
    final pct = (fraction * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pct > 0)
          Text(
            '$pct%',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          )
        else
          const SizedBox(height: 16),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: fraction > 0 ? barHeight : maxBarHeight,
          decoration: BoxDecoration(
            color: fraction > 0 ? AppColors.primary : AppColors.chipBackground,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Debt Card ────────────────────────────────────────────────────────────────

class _DebtCard extends StatelessWidget {
  final Booking booking;
  final List<Dog> dogs;
  final DateFormat dateFormat;

  const _DebtCard({
    required this.booking,
    required this.dogs,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final dogNames = booking.dogIds
        .map((id) {
          final idx = dogs.indexWhere((d) => d.id == id);
          return idx != -1 ? dogs[idx].name : id;
        })
        .join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(dogNames),
        subtitle: Text(
          '${dateFormat.format(booking.startDate)} – ${dateFormat.format(booking.endDate)}',
        ),
        trailing: Text(
          '₪${booking.totalPrice!.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ── Income Details Modal ─────────────────────────────────────────────────────

class _IncomeDetailsSheet extends StatelessWidget {
  final List<Booking> bookings;
  final DogProvider dogProvider;

  const _IncomeDetailsSheet({
    required this.bookings,
    required this.dogProvider,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yy', 'he');
    final sorted = [...bookings]
      ..sort((a, b) => (b.paidAt ?? b.startDate).compareTo(a.paidAt ?? a.startDate));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'פירוט הכנסות',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${bookings.length} הזמנות',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
              ],
            ),
          ),

          if (sorted.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'אין הכנסות לחודש זה',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final b = sorted[i];
                  final ownerName = b.dogIds
                      .map((id) {
                        final idx = dogProvider.dogs.indexWhere((d) => d.id == id);
                        return idx != -1 ? dogProvider.dogs[idx].ownerName : '';
                      })
                      .where((n) => n.isNotEmpty)
                      .toSet()
                      .join(', ');

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        // Owner name
                        Expanded(
                          flex: 3,
                          child: Text(
                            ownerName.isNotEmpty ? ownerName : '—',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        // Paid amount
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₪${b.totalPrice?.toStringAsFixed(0) ?? '—'}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Payment method
                        Expanded(
                          flex: 2,
                          child: Text(
                            b.paymentMethod?.hebrewLabel ?? '—',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        // Payment date
                        SizedBox(
                          width: 60,
                          child: Text(
                            b.paidAt != null ? dateFormat.format(b.paidAt!) : '—',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
