import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingType { boarding, introMeeting }

extension BookingTypeExtension on BookingType {
  String get firestoreValue {
    switch (this) {
      case BookingType.boarding:
        return 'boarding';
      case BookingType.introMeeting:
        return 'intro_meeting';
    }
  }

  String get hebrewLabel {
    switch (this) {
      case BookingType.boarding:
        return 'אירוח';
      case BookingType.introMeeting:
        return 'פגישת היכרות';
    }
  }

  static BookingType fromFirestoreValue(String value) {
    for (final t in BookingType.values) {
      if (t.firestoreValue == value) return t;
    }
    return BookingType.boarding;
  }
}

enum BookingStatus { upcoming, active, completed }

enum PaymentMethod { bit, cash, bankTransfer }

extension PaymentMethodExtension on PaymentMethod {
  String get firestoreValue {
    switch (this) {
      case PaymentMethod.bit:
        return 'bit';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }

  String get hebrewLabel {
    switch (this) {
      case PaymentMethod.bit:
        return 'ביט';
      case PaymentMethod.cash:
        return 'מזומן';
      case PaymentMethod.bankTransfer:
        return 'העברה בנקאית';
    }
  }

  static PaymentMethod? fromFirestoreValue(String? value) {
    if (value == null) return null;
    for (final m in PaymentMethod.values) {
      if (m.firestoreValue == value) return m;
    }
    return null;
  }
}

class Booking {
  final String id;
  final List<String> dogIds;
  final BookingType type;
  final String? kennelId;
  final DateTime startDate;
  final DateTime endDate;
  final String? meetingTime;
  final double? totalPrice;
  final bool isPaid;
  final PaymentMethod? paymentMethod;
  final List<String> contractPhotoUrls;
  final DateTime createdAt;
  final DateTime? paidAt;

  const Booking({
    required this.id,
    required this.dogIds,
    required this.type,
    this.kennelId,
    required this.startDate,
    required this.endDate,
    this.meetingTime,
    this.totalPrice,
    this.isPaid = false,
    this.paymentMethod,
    this.contractPhotoUrls = const [],
    required this.createdAt,
    this.paidAt,
  });

  // Legacy accessor — first photo URL for backward compat
  String? get contractPhotoUrl =>
      contractPhotoUrls.isNotEmpty ? contractPhotoUrls.first : null;

  // Computed — not stored in Firestore
  BookingStatus get status {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (todayDate.isBefore(start)) return BookingStatus.upcoming;
    if (todayDate.isAfter(end)) return BookingStatus.completed;
    return BookingStatus.active;
  }

  bool get hasContract => contractPhotoUrls.isNotEmpty;

  bool get needsContractAlert =>
      type == BookingType.boarding &&
      (status == BookingStatus.upcoming || status == BookingStatus.active) &&
      !hasContract;

  int get numberOfDays => endDate.difference(startDate).inDays + 1;

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dogIdsList = (data['dogIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();

    return Booking(
      id: doc.id,
      dogIds: dogIdsList,
      type: BookingTypeExtension.fromFirestoreValue(
          data['type'] as String? ?? 'boarding'),
      kennelId: data['kennelId'] as String?,
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      meetingTime: data['meetingTime'] as String?,
      totalPrice: (data['totalPrice'] as num?)?.toDouble(),
      isPaid: data['isPaid'] as bool? ?? false,
      paymentMethod:
          PaymentMethodExtension.fromFirestoreValue(data['paymentMethod'] as String?),
      contractPhotoUrls: _parseContractUrls(data),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogIds': dogIds,
      'type': type.firestoreValue,
      'kennelId': kennelId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'meetingTime': meetingTime,
      'totalPrice': totalPrice,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod?.firestoreValue,
      'contractPhotoUrls': contractPhotoUrls,
      'contractPhotoUrl': contractPhotoUrls.isNotEmpty ? contractPhotoUrls.first : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  Booking copyWith({
    String? id,
    List<String>? dogIds,
    BookingType? type,
    String? kennelId,
    DateTime? startDate,
    DateTime? endDate,
    String? meetingTime,
    double? totalPrice,
    bool? isPaid,
    PaymentMethod? paymentMethod,
    List<String>? contractPhotoUrls,
    DateTime? createdAt,
    Object? paidAt = _sentinel,
  }) {
    return Booking(
      id: id ?? this.id,
      dogIds: dogIds ?? this.dogIds,
      type: type ?? this.type,
      kennelId: kennelId ?? this.kennelId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      meetingTime: meetingTime ?? this.meetingTime,
      totalPrice: totalPrice ?? this.totalPrice,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      contractPhotoUrls: contractPhotoUrls ?? this.contractPhotoUrls,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt == _sentinel ? this.paidAt : paidAt as DateTime?,
    );
  }
}

const Object _sentinel = Object();

List<String> _parseContractUrls(Map<String, dynamic> data) {
  final list = data['contractPhotoUrls'];
  if (list is List && list.isNotEmpty) {
    return list.whereType<String>().toList();
  }
  // Backward compat: single URL field from old documents
  final single = data['contractPhotoUrl'] as String?;
  if (single != null && single.isNotEmpty) return [single];
  return const [];
}
