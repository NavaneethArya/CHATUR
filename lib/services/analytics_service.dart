// import 'package:firebase_analytics/firebase_analytics.dart';

// class AnalyticsService {
//   static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

//   // Skill Events
//   static Future<void> logSkillPosted({
//     required String category,
//     required String skillId,
//   }) async {
//     await _analytics.logEvent(
//       name: 'skill_posted',
//       parameters: {
//         'category': category,
//         'skill_id': skillId,
//       },
//     );
//   }

//   static Future<void> logSkillViewed({
//     required String skillId,
//     required String category,
//   }) async {
//     await _analytics.logEvent(
//       name: 'skill_viewed',
//       parameters: {
//         'skill_id': skillId,
//         'category': category,
//       },
//     );
//   }

//   static Future<void> logSkillSaved({
//     required String skillId,
//     required bool isSaving,
//   }) async {
//     await _analytics.logEvent(
//       name: isSaving ? 'skill_saved' : 'skill_unsaved',
//       parameters: {'skill_id': skillId},
//     );
//   }

//   // Booking Events
//   static Future<void> logBookingInitiated({
//     required String skillId,
//     required String providerId,
//   }) async {
//     await _analytics.logEvent(
//       name: 'booking_initiated',
//       parameters: {
//         'skill_id': skillId,
//         'provider_id': providerId,
//       },
//     );
//   }

//   static Future<void> logBookingCompleted({
//     required String skillId,
//     required String bookingId,
//   }) async {
//     await _analytics.logEvent(
//       name: 'booking_completed',
//       parameters: {
//         'skill_id': skillId,
//         'booking_id': bookingId,
//       },
//     );
//   }

//   // Search Events
//   static Future<void> logSearch({
//     required String query,
//     required int resultsCount,
//   }) async {
//     await _analytics.logEvent(
//       name: 'search',
//       parameters: {
//         'search_term': query,
//         'results_count': resultsCount,
//       },
//     );
//   }

//   static Future<void> logFilterApplied({
//     required String filterType,
//     required String filterValue,
//   }) async {
//     await _analytics.logEvent(
//       name: 'filter_applied',
//       parameters: {
//         'filter_type': filterType,
//         'filter_value': filterValue,
//       },
//     );
//   }

//   // Contact Events
//   static Future<void> logContactAttempt({
//     required String contactType, // 'phone', 'whatsapp', 'chat'
//     required String providerId,
//   }) async {
//     await _analytics.logEvent(
//       name: 'contact_attempt',
//       parameters: {
//         'contact_type': contactType,
//         'provider_id': providerId,
//       },
//     );
//   }

//   // Screen Views
//   static Future<void> logScreenView(String screenName) async {
//     await _analytics.logScreenView(
//       screenName: screenName,
//     );
//   }

//   // User Properties
//   static Future<void> setUserRole(String role) async {
//     await _analytics.setUserProperty(
//       name: 'user_role',
//       value: role, // 'provider', 'customer', 'both'
//     );
//   }
// }
