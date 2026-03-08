import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../models/dog_model.dart';
import '../../providers/dog_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/dogs/dog_photo_picker.dart';
import '../../widgets/dogs/dog_tags_selector.dart';

enum FormMode { add, edit }

class DogFormScreen extends StatefulWidget {
  final Dog? dog;

  const DogFormScreen({super.key, this.dog});

  FormMode get mode => dog == null ? FormMode.add : FormMode.edit;

  @override
  State<DogFormScreen> createState() => _DogFormScreenState();
}

class _DogFormScreenState extends State<DogFormScreen> {
  static const _kNewOwner = '__new__';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _ownerPhoneController;
  late final TextEditingController _notesController;
  late final TextEditingController _ageController;
  late final TextEditingController _dailyRateController;
  late final TextEditingController _mealsPerDayController;
  late final TextEditingController _additionalNotesController;
  late List<String> _selectedTags;
  bool? _isNeutered;
  bool? _isMale;
  File? _imageFile;
  String? _selectedOwnerPhone;

  @override
  void initState() {
    super.initState();
    final d = widget.dog;
    _nameController = TextEditingController(text: d?.name ?? '');
    _breedController = TextEditingController(text: d?.breed ?? '');
    _ownerNameController = TextEditingController(text: d?.ownerName ?? '');
    _ownerPhoneController = TextEditingController(text: d?.ownerPhone ?? '');
    _notesController = TextEditingController(text: d?.notes ?? '');
    _ageController = TextEditingController(
        text: d?.ageYears != null ? d!.ageYears.toString() : '');
    _dailyRateController = TextEditingController(
        text: d?.dailyRate != null ? d!.dailyRate.toString() : '');
    _mealsPerDayController = TextEditingController(
        text: d?.mealsPerDay != null ? d!.mealsPerDay.toString() : '');
    _additionalNotesController = TextEditingController(text: d?.additionalNotes ?? '');
    _selectedTags = List<String>.from(d?.tags ?? []);
    _isNeutered = d?.isNeutered;
    _isMale = d?.isMale;
    _selectedOwnerPhone = d?.ownerPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _notesController.dispose();
    _ageController.dispose();
    _dailyRateController.dispose();
    _mealsPerDayController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<DogProvider>();
    final now = DateTime.now();

    if (widget.mode == FormMode.add) {
      final dog = Dog(
        id: '',
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        tags: _selectedTags,
        ageYears: int.tryParse(_ageController.text),
        dailyRate: double.tryParse(_dailyRateController.text),
        isNeutered: _isNeutered,
        isMale: _isMale,
        mealsPerDay: int.tryParse(_mealsPerDayController.text),
        additionalNotes: _additionalNotesController.text.trim().isEmpty ? null : _additionalNotesController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await provider.addDog(dog: dog, photoFile: _imageFile);
    } else {
      final dog = widget.dog!.copyWith(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        tags: _selectedTags,
        ageYears: int.tryParse(_ageController.text),
        dailyRate: double.tryParse(_dailyRateController.text),
        isNeutered: _isNeutered,
        isMale: _isMale,
        mealsPerDay: int.tryParse(_mealsPerDayController.text),
        additionalNotes: _additionalNotesController.text.trim().isEmpty ? null : _additionalNotesController.text.trim(),
        updatedAt: now,
      );
      await provider.updateDog(dog: dog, photoFile: _imageFile);
    }

    if (!mounted) return;

    final error = provider.errorMessage;
    if (error != null) {
      showErrorSnackbar(context, error);
      provider.clearError();
    } else {
      showSuccessSnackbar(
        context,
        widget.mode == FormMode.add ? AppStrings.dogAdded : AppStrings.dogUpdated,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.confirmDelete),
        content: const Text(AppStrings.confirmDeleteMessage),
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

    final provider = context.read<DogProvider>();
    await provider.deleteDog(widget.dog!.id);

    if (!mounted) return;

    if (provider.errorMessage != null) {
      showErrorSnackbar(context, provider.errorMessage!);
      provider.clearError();
    } else {
      showSuccessSnackbar(context, AppStrings.dogDeleted);
      // Pop back to list (pop twice — detail + form)
      Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/dogs');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DogProvider>();
    final isLoading = provider.isLoading;
    final isEdit = widget.mode == FormMode.edit;

    final dogs = provider.dogs;
    final ownerMap = {for (final dog in dogs) dog.ownerPhone: dog.ownerName};
    if (_selectedOwnerPhone != null && !ownerMap.containsKey(_selectedOwnerPhone!)) {
      ownerMap[_selectedOwnerPhone!] = _ownerNameController.text;
    }
    final sortedOwners = ownerMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final dropdownValue = _selectedOwnerPhone ?? _kNewOwner;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? AppStrings.editDog : AppStrings.addDog),
          actions: [
            if (isEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade200,
                tooltip: AppStrings.deleteDog,
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DogPhotoPicker(
                imageFile: _imageFile,
                existingPhotoUrl: widget.dog?.photoUrl,
                onImageSelected: (file) => setState(() => _imageFile = file),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.dogName,
                controller: _nameController,
                validator: Validators.required,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: AppStrings.breed,
                controller: _breedController,
                validator: Validators.required,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: AppStrings.age,
                controller: _ageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              // ── Owner dropdown ──────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: dropdownValue,
                decoration: const InputDecoration(labelText: AppStrings.selectOwner),
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: _kNewOwner,
                    child: Row(children: [
                      const Icon(Icons.person_add_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Text(AppStrings.createNewOwner),
                    ]),
                  ),
                  ...sortedOwners.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  )),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  if (value == _kNewOwner) {
                    setState(() {
                      _selectedOwnerPhone = null;
                      _ownerNameController.clear();
                      _ownerPhoneController.clear();
                    });
                  } else {
                    setState(() {
                      _selectedOwnerPhone = value;
                      _ownerNameController.text = ownerMap[value] ?? '';
                      _ownerPhoneController.text = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // ── Name + phone: only shown when creating a new owner ──
              if (_selectedOwnerPhone == null) ...[
                AppTextField(
                  label: AppStrings.ownerName,
                  controller: _ownerNameController,
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: AppStrings.ownerPhone,
                  controller: _ownerPhoneController,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
              ],
              AppTextField(
                label: AppStrings.dailyRate,
                controller: _dailyRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'מס\' ארוחות ביום',
                controller: _mealsPerDayController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              // ── Gender ─────────────────────────────────────────────
              Row(
                children: [
                  const Text('מין', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('זכר'),
                        icon: Icon(Icons.male, size: 18),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('נקבה'),
                        icon: Icon(Icons.female, size: 18),
                      ),
                    ],
                    selected: _isMale == null ? {} : {_isMale!},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (v) =>
                        setState(() => _isMale = v.isEmpty ? null : v.first),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: const Text('מסורס / מעוקרת'),
                value: _isNeutered ?? false,
                onChanged: (value) => setState(() => _isNeutered = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 4),
              AppTextField(
                label: AppStrings.notes,
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'הערות נוספות',
                controller: _additionalNotesController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              DogTagsSelector(
                selectedTags: _selectedTags,
                onChanged: (tags) => setState(() => _selectedTags = tags),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: isEdit ? AppStrings.saveChanges : AppStrings.addNewDog,
                onPressed: _submit,
                isLoading: isLoading,
              ),
              if (isEdit) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: AppStrings.deleteDog,
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
