class FirestorePaths {
  FirestorePaths._();

  static const dogs = 'dogs';
  static const bookings = 'bookings';

  static String dogDocument(String dogId) => 'dogs/$dogId';
  static String bookingDocument(String bookingId) => 'bookings/$bookingId';
}
