import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection(FirestorePaths.bookings);

  Stream<List<Booking>> watchBookings() {
    return _bookings
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Booking.fromFirestore).toList());
  }

  Future<String> addBooking(Booking booking) async {
    final doc = await _bookings.add(booking.toMap());
    return doc.id;
  }

  Future<void> updateBooking(Booking booking) {
    return _bookings.doc(booking.id).update(booking.toMap());
  }

  Future<void> deleteBooking(String id) {
    return _bookings.doc(id).delete();
  }

  Future<void> updateContractUrl(String bookingId, String url) {
    return _bookings.doc(bookingId).update({'contractPhotoUrl': url});
  }

  Future<void> addContractUrl(String bookingId, String url) {
    return _bookings.doc(bookingId).update({
      'contractPhotoUrls': FieldValue.arrayUnion([url]),
      'contractPhotoUrl': url,
    });
  }

  Future<void> removeContractUrl(String bookingId, String url) {
    return _bookings.doc(bookingId).update({
      'contractPhotoUrls': FieldValue.arrayRemove([url]),
    });
  }
}
