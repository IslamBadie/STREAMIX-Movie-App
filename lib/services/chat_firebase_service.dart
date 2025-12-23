import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service that manages chat conversation persistence.
///
/// - For authenticated users it stores conversations/messages in Firestore under
///   `users/{uid}/conversations/...`.
/// - For guest users it persists conversations locally using SharedPreferences.
class ChatFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _conversationsKey = 'chat_conversations';
  static const String _currentConversationKey = 'current_conversation';

  /// Save a message to a conversation. If the user is authenticated, messages
  /// are saved in Firestore; otherwise they are saved locally as a fallback.
  Future<void> saveMessage({
    required String message,
    required bool isUser,
    required String conversationId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .add({
          'message': message,
          'isUser': isUser,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('conversations')
            .doc(conversationId)
            .update({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      } else {
        await _saveMessageLocally(message, isUser, conversationId);
      }
    } catch (e) {
      // On any error, fallback to local save to avoid data loss
      await _saveMessageLocally(message, isUser, conversationId);
    }
  }

  /// Persist a message locally using SharedPreferences as a JSON string list.
  Future<void> _saveMessageLocally(
      String message, bool isUser, String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = prefs.getStringList(_conversationsKey) ?? [];

      String conversationJson = '';
      for (int i = 0; i < conversations.length; i++) {
        if (conversations[i].contains('"id":"$conversationId"')) {
          conversationJson = conversations[i];
          conversations.removeAt(i);
          break;
        }
      }

      Map<String, dynamic> conversationData;
      if (conversationJson.isNotEmpty) {
        conversationData =
            Map<String, dynamic>.from(json.decode(conversationJson));
      } else {
        conversationData = {
          'id': conversationId,
          'createdAt': DateTime.now().toIso8601String(),
          'lastMessage': message,
          'lastMessageTime': DateTime.now().toIso8601String(),
          'messages': <Map<String, dynamic>>[],
        };
      }

      final messages =
          List<Map<String, dynamic>>.from(conversationData['messages'] ?? []);
      messages.add({
        'message': message,
        'isUser': isUser,
        'timestamp': DateTime.now().toIso8601String(),
      });

      conversationData['messages'] = messages;
      conversationData['lastMessage'] = message;
      conversationData['lastMessageTime'] = DateTime.now().toIso8601String();

      conversations.add(json.encode(conversationData));
      await prefs.setStringList(_conversationsKey, conversations);
      await prefs.setString(_currentConversationKey, conversationId);
    } catch (e) {
      // Silently fail - data loss is minimal for local-only chats
    }
  }

  /// Create a new conversation. Returns the conversation id.
  Future<String> createConversation() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('conversations')
            .add({
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        return docRef.id;
      } else {
        return await _createConversationLocally();
      }
    } catch (e) {
      return await _createConversationLocally();
    }
  }

  Future<String> _createConversationLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = prefs.getStringList(_conversationsKey) ?? [];

      final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
      final conversationData = {
        'id': conversationId,
        'createdAt': DateTime.now().toIso8601String(),
        'lastMessage': '',
        'lastMessageTime': DateTime.now().toIso8601String(),
        'messages': <Map<String, dynamic>>[],
      };

      conversations.add(json.encode(conversationData));
      await prefs.setStringList(_conversationsKey, conversations);
      await prefs.setString(_currentConversationKey, conversationId);

      return conversationId;
    } catch (e) {
      rethrow;
    }
  }

  /// Return the latest conversation id for the current user (or guest).
  Future<String?> getLastConversation() async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('conversations')
            .orderBy('lastMessageTime', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          return null;
        }

        final conversationId = snapshot.docs.first.id;
        return conversationId;
      } else {
        return await _getLastConversationLocally();
      }
    } catch (e) {
      return await _getLastConversationLocally();
    }
  }

  Future<String?> _getLastConversationLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final currentId = prefs.getString(_currentConversationKey);
      if (currentId != null) return currentId;

      final conversations = prefs.getStringList(_conversationsKey) ?? [];
      if (conversations.isEmpty) return null;

      String? latestConversationId;
      DateTime? latestTime;

      for (final conversationJson in conversations) {
        try {
          final data = Map<String, dynamic>.from(json.decode(conversationJson));
          final timeStr = data['lastMessageTime'] as String?;
          if (timeStr != null) {
            final time = DateTime.parse(timeStr);
            if (latestTime == null || time.isAfter(latestTime)) {
              latestTime = time;
              latestConversationId = data['id'] as String?;
            }
          }
        } catch (e) {
          // Skip malformed conversation data
        }
      }

      return latestConversationId;
    } catch (e) {
      return null;
    }
  }

  /// Get messages for a given conversation id. Falls back to local storage if needed.
  Future<List<Map<String, dynamic>>> getConversationMessages(
      String conversationId) async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .orderBy('timestamp')
            .get();

        return snapshot.docs.map((doc) => doc.data()).toList();
      } else {
        return await _getConversationMessagesLocally(conversationId);
      }
    } catch (e) {
      return await _getConversationMessagesLocally(conversationId);
    }
  }

  Future<List<Map<String, dynamic>>> _getConversationMessagesLocally(
      String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = prefs.getStringList(_conversationsKey) ?? [];

      for (final conversationJson in conversations) {
        if (conversationJson.contains('"id":"$conversationId"')) {
          final data = Map<String, dynamic>.from(json.decode(conversationJson));
          final messages =
              List<Map<String, dynamic>>.from(data['messages'] ?? []);

          messages.sort((a, b) {
            final timeA = DateTime.parse(a['timestamp'] as String);
            final timeB = DateTime.parse(b['timestamp'] as String);
            return timeA.compareTo(timeB);
          });

          return messages;
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// List all conversations for the authenticated user.
  Future<List<Map<String, dynamic>>> getUserConversations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .orderBy('lastMessageTime', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a conversation and its messages for the authenticated user.
  Future<void> deleteConversation(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final messagesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversationId)
          .delete();
    } catch (e) {
      // Silently fail - conversation may not exist
    }
  }
}
