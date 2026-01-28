import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Standardize the Chat Room ID so both apps look at the same document
  Future<String> getOrCreateChatRoom(String otherUserId, {String? currentUserId}) async {
    final userId = currentUserId ?? _auth.currentUser?.uid;
    if (userId == null) throw 'User not authenticated';

    // Sorting ensures "A_B" and "B_A" always become the same unique ID "A_B"
    final participants = [userId, otherUserId]..sort();
    final chatRoomId = participants.join('_');

    final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final chatRoomDoc = await chatRoomRef.get();

    if (!chatRoomDoc.exists) {
      // Fetch user types to identify who is the doctor for the list filter
      final currentUserDoc = await _firestore.collection('users').doc(userId).get();
      final isCurrentDoctor = currentUserDoc.data()?['userType'] == 'doctor';

      await chatRoomRef.set({
        'participants': participants,
        'doctorId': isCurrentDoctor ? userId : otherUserId, // Crucial for Doctor's list
        'userId': isCurrentDoctor ? otherUserId : userId,    // The Patient's ID
        'userName': isCurrentDoctor ? 'Patient' : (currentUserDoc.data()?['displayName'] ?? 'Patient'),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    return chatRoomId;
  }

  // Fetch messages - uses 'timestamp' field to order them
  Stream<QuerySnapshot> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String message,
    String? senderId,
    String? senderName,
    String? imageUrl, // Changed to optional (?) to avoid errors
  }) async {
    final sender = senderId ?? _auth.currentUser?.uid ?? '';

    final messageData = {
      'senderId': sender,
      'senderName': senderName ?? 'User',
      'message': message,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    };

    // 1. Add message to sub-collection
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // 2. Update main room doc for the list view
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final unread = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}