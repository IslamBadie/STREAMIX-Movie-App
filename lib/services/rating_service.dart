import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing movie ratings and reviews
class RatingService {
  static final RatingService _instance = RatingService._internal();

  factory RatingService() => _instance;

  RatingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add or update a movie rating
  Future<void> rateMovie({
    required int movieId,
    required double rating,
    String? review,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to rate movies');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ratings')
          .doc(movieId.toString())
          .set({
        'movieId': movieId,
        'rating': rating,
        'review': review ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get user rating for a movie
  Future<Map<String, dynamic>?> getUserRating(int movieId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ratings')
          .doc(movieId.toString())
          .get();

      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Get average rating for a movie from all users
  Future<double> getAverageRating(int movieId) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('ratings')
          .where('movieId', isEqualTo: movieId)
          .get();

      if (querySnapshot.docs.isEmpty) return 0.0;

      double total = 0;
      for (var doc in querySnapshot.docs) {
        total += (doc['rating'] as num).toDouble();
      }

      return total / querySnapshot.docs.length;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get all ratings for a movie
  Future<List<Map<String, dynamic>>> getMovieRatings(int movieId) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('ratings')
          .where('movieId', isEqualTo: movieId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete user rating
  Future<void> deleteRating(int movieId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ratings')
          .doc(movieId.toString())
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
