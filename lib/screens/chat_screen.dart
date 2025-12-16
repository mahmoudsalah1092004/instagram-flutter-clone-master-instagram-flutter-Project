// screens/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final picker = ImagePicker();
  late String chatId;

  @override
  void initState() {
    super.initState();
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    chatId = _chatService.getChatId(myUid, widget.otherUserId);
  }

  Future<void> _sendText() async {
    if (_controller.text.trim().isEmpty) return;

    await _chatService.sendTextMessage(
      chatId: chatId,
      text: _controller.text.trim(),
    );

    _controller.clear();
  }

  Future<void> _sendImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    await _chatService.sendImageMessage(
      chatId: chatId,
      imageFile: File(file.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatService.getMessages(chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data() as Map<String, dynamic>;
                    final isMe = msg["senderId"] ==
                        FirebaseAuth.instance.currentUser!.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              isMe ? Colors.blue: Colors.brown[900],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: msg["type"] == "image"
                            ? Image.network(
                                msg["imageUrl"],
                                height: 200,
                              )
                            : Text(msg["text"]),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ------- Send Box -------
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[5000],
            child: Row(
              children: [
                IconButton(
                  onPressed: _sendImage,
                  icon: const Icon(Icons.photo),
                ),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "اكتب رسالة...",
                    ),
                  ),
                ),

                IconButton(
                  onPressed: _sendText,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
