import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/chat_service.dart';

class DoctorChatScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String? doctorPhotoURL;
  final String? patientId;
  final String? patientName;

  const DoctorChatScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.doctorPhotoURL,
    this.patientId,
    this.patientName,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _chatRoomId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    // Start the setup sequence
    _setupChatSystem();
  }

  // FIXED: Sequence to ensure role is known BEFORE room ID is created
  Future<void> _setupChatSystem() async {
    await _checkUserRole();
    await _initializeChat();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        final userType = userDoc.data()?['userType'] as String?;
        setState(() => _isDoctor = userType == 'doctor');
      }
    }
  }

  Future<void> _initializeChat() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not authenticated';

      // Logical check: If I am the doctor, the "other" person is the patient.
      final otherUserId = _isDoctor ? widget.patientId : widget.doctorId;

      if (otherUserId == null) {
        throw 'Connection error: User ID mismatch.';
      }

      final chatRoomId = await _chatService.getOrCreateChatRoom(
        otherUserId,
        currentUserId: user.uid,
      );

      if (mounted) {
        setState(() {
          _chatRoomId = chatRoomId;
          _isLoading = false;
        });

        await _chatService.markMessagesAsRead(chatRoomId, user.uid);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatRoomId == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      // FIXED: Removed the syntax error/extra comma from your previous snippet
      await _chatService.sendMessage(
        chatRoomId: _chatRoomId!,
        message: message,
        senderId: user?.uid,
        senderName: user?.displayName ?? user?.email,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t send: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isSending = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _chatService.sendMessage(
        chatRoomId: _chatRoomId!,
        message: '[Image]',
        senderId: user.uid,
        senderName: user.displayName ?? user.email,
        imageUrl: image.path,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final otherUserName = _isDoctor ? widget.patientName : widget.doctorName;
    final otherUserPhoto = _isDoctor ? null : widget.doctorPhotoURL;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(otherUserName ?? 'Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green.shade100,
              backgroundImage: (otherUserPhoto != null && otherUserPhoto.isNotEmpty)
                  ? NetworkImage(otherUserPhoto) : null,
              child: (otherUserPhoto == null || otherUserPhoto.isEmpty)
                  ? Icon(_isDoctor ? Icons.person : Icons.medical_services,
                  color: Colors.green.shade700, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherUserName ?? 'Chat',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Online', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade50,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(_chatRoomId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true, // Matches descending: true in ChatService
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == user?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green.shade600 : Colors.white,
                          borderRadius: BorderRadius.circular(18).copyWith(
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
                              const Icon(Icons.image, size: 50)
                            else
                              Text(data['message'] ?? '',
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(_formatTimestamp(data['timestamp'] as Timestamp?),
                                style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input Bar
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image, color: Colors.green), onPressed: _isSending ? null : _pickAndSendImage),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.green),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}