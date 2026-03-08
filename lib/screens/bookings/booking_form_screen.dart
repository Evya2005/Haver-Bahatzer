import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/dog_provider.dart';
import '../../widgets/bookings/dog_multi_selector.dart';
import '../../widgets/bookings/kennel_selector.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';

enum BookingFormMode { add, edit }

class BookingFormScreen extends StatefulWidget {
  final Booking? booking;
  final DateTime? initialDate;

  const BookingFormScreen({super.key, this.booking, this.initialDate});

  BookingFormMode get mode => booking == null ? BookingFormMode.add : BookingFormMode.edit;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late BookingType _selectedType;
  late List<String> _selectedDogIds;
  late String? _selectedKennelId;
  late DateTime _startDate;
  late DateTime _endDate;
  TimeOfDay? _meetingTime;
  late TextEditingController _priceController;
  late bool _isPaid;
  DateTime? _paidAt;
  PaymentMethod? _paymentMethod;

  final _dateFormat = DateFormat('dd/MM/yyyy', 'he');

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    _selectedType = b?.type ?? BookingType.boarding;
    _selectedDogIds = List.from(b?.dogIds ?? []);
    _selectedKennelId = b?.kennelId;
    _startDate = b?.startDate ?? widget.initialDate ?? DateTime.now();
    _endDate = b?.endDate ?? widget.initialDate ?? DateTime.now();
    _priceController =
        TextEditingController(text: b?.totalPrice?.toStringAsFixed(0) ?? '');
    _isPaid = b?.isPaid ?? false;
    _paidAt = b?.paidAt;
    _paymentMethod = b?.paymentMethod;

    if (b?.meetingTime != null) {
      final parts = b!.meetingTime!.split(':');
      if (parts.length == 2) {
        _meetingTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart ? DateTime(2020) : _startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
      locale: const Locale('he', 'IL'),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
    _recalcPrice();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _meetingTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _meetingTime = picked);
  }

  void _recalcPrice() {
    if (_selectedType != BookingType.boarding) return;
    final dogs = context.read<DogProvider>().dogs;
    final days = _endDate.difference(_startDate).inDays + 1;
    final total = dogs
        .where((d) => _selectedDogIds.contains(d.id))
        .fold<double>(0, (sum, d) => sum + (d.dailyRate ?? 0));
    if (total > 0) {
      _priceController.text = (total * days).toStringAsFixed(0);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BookingProvider>();

    // Conflict detection
    final dogConflict = provider.checkDogConflict(
      _selectedDogIds,
      _startDate,
      _endDate,
      excludeId: widget.booking?.id,
    );
    if (dogConflict != null) {
      if (mounted) showErrorSnackbar(context, dogConflict);
      return;
    }

    if (_selectedType == BookingType.boarding && _selectedKennelId != null) {
      final kennelConflict = provider.checkKennelConflict(
        _selectedKennelId!,
        _startDate,
        _endDate,
        excludeId: widget.booking?.id,
      );
      if (kennelConflict != null) {
        if (mounted) showErrorSnackbar(context, kennelConflict);
        return;
      }
    }

    final meetingTimeStr = _meetingTime != null
        ? '${_meetingTime!.hour.toString().padLeft(2, '0')}:${_meetingTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final now = DateTime.now();

    if (widget.mode == BookingFormMode.add) {
      final booking = Booking(
        id: '',
        dogIds: _selectedDogIds,
        type: _selectedType,
        kennelId: _selectedType == BookingType.boarding ? _selectedKennelId : null,
        startDate: _startDate,
        endDate: _selectedType == BookingType.boarding ? _endDate : _startDate,
        meetingTime: _selectedType == BookingType.introMeeting ? meetingTimeStr : null,
        totalPrice: _selectedType == BookingType.boarding
            ? double.tryParse(_priceController.text)
            : null,
        isPaid: _isPaid,
        paymentMethod: _paymentMethod,
        paidAt: _isPaid ? (_paidAt ?? DateTime.now()) : null,
        createdAt: now,
      );
      await provider.addBooking(booking);
    } else {
      final updated = widget.booking!.copyWith(
        dogIds: _selectedDogIds,
        type: _selectedType,
        kennelId: _selectedType == BookingType.boarding ? _selectedKennelId : null,
        startDate: _startDate,
        endDate: _selectedType == BookingType.boarding ? _endDate : _startDate,
        meetingTime: _selectedType == BookingType.introMeeting ? meetingTimeStr : null,
        totalPrice: _selectedType == BookingType.boarding
            ? double.tryParse(_priceController.text)
            : null,
        isPaid: _isPaid,
        paymentMethod: _paymentMethod,
        paidAt: _isPaid ? (_paidAt ?? DateTime.now()) : null,
      );
      await provider.updateBooking(updated);
    }

    if (!mounted) return;

    final error = provider.errorMessage;
    if (error != null) {
      showErrorSnackbar(context, error);
      provider.clearError();
    } else {
      showSuccessSnackbar(
        context,
        widget.mode == BookingFormMode.add
            ? AppStrings.bookingAdded
            : AppStrings.bookingUpdated,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.confirmDelete),
        content: const Text(AppStrings.confirmDeleteBooking),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<BookingProvider>();
    await provider.deleteBooking(widget.booking!.id);

    if (!mounted) return;

    if (provider.errorMessage != null) {
      showErrorSnackbar(context, provider.errorMessage!);
      provider.clearError();
    } else {
      showSuccessSnackbar(context, AppStrings.bookingDeleted);
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<BookingProvider>().isLoading;
    final isEdit = widget.mode == BookingFormMode.edit;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? AppStrings.editBooking : AppStrings.addBooking),
          actions: [
            if (isEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade200,
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Type toggle
              SegmentedButton<BookingType>(
                segments: const [
                  ButtonSegment(
                    value: BookingType.boarding,
                    label: Text(AppStrings.boarding),
                    icon: Icon(Icons.home_outlined),
                  ),
                  ButtonSegment(
                    value: BookingType.introMeeting,
                    label: Text(AppStrings.introMeeting),
                    icon: Icon(Icons.handshake_outlined),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) =>
                    setState(() => _selectedType = set.first),
              ),
              const SizedBox(height: 20),

              // Dog selector
              DogMultiSelector(
                selectedDogIds: _selectedDogIds,
                onChanged: (ids) {
                  setState(() => _selectedDogIds = ids);
                  _recalcPrice();
                },
              ),
              const SizedBox(height: 16),

              // Boarding-only fields
              if (_selectedType == BookingType.boarding) ...[
                KennelSelector(
                  selectedKennelId: _selectedKennelId,
                  onChanged: (id) => setState(() => _selectedKennelId = id),
                ),
                const SizedBox(height: 16),
                _DateTile(
                  label: AppStrings.startDate,
                  date: _startDate,
                  dateFormat: _dateFormat,
                  onTap: () => _pickDate(isStart: true),
                ),
                const SizedBox(height: 12),
                _DateTile(
                  label: AppStrings.endDate,
                  date: _endDate,
                  dateFormat: _dateFormat,
                  onTap: () => _pickDate(isStart: false),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: AppStrings.totalPrice,
                    prefixText: '₪',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: _isPaid,
                  onChanged: (v) => setState(() {
                    _isPaid = v;
                    if (v) {
                      _paidAt ??= DateTime.now();
                    } else {
                      _paidAt = null;
                    }
                  }),
                  title: const Text(AppStrings.isPaid),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_isPaid) ...[
                  DropdownButtonFormField<PaymentMethod>(
                    initialValue: _paymentMethod,
                    decoration:
                        const InputDecoration(labelText: AppStrings.paymentMethod),
                    items: PaymentMethod.values
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.hebrewLabel),
                            ))
                        .toList(),
                    onChanged: (m) => setState(() => _paymentMethod = m),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // Intro-only fields
              if (_selectedType == BookingType.introMeeting) ...[
                _DateTile(
                  label: AppStrings.date,
                  date: _startDate,
                  dateFormat: _dateFormat,
                  onTap: () => _pickDate(isStart: true),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.meetingTime),
                  trailing: Text(
                    _meetingTime != null
                        ? _meetingTime!.format(context)
                        : '—',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: _pickTime,
                ),
              ],

              const SizedBox(height: 28),
              AppButton(
                label: isEdit ? AppStrings.saveChanges : AppStrings.addBooking,
                onPressed: _submit,
                isLoading: isLoading,
              ),
              if (isEdit) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: AppStrings.delete,
                  onPressed: _confirmDelete,
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.date,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(
        dateFormat.format(date),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      onTap: onTap,
    );
  }
}
