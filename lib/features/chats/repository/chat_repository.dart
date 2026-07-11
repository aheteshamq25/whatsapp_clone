import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_clone/commons/enum/message_enum.dart';
import 'package:whatsapp_clone/commons/utils/utils.dart';
import 'package:whatsapp_clone/features/auth/controller/common_firebase_storage_repository.dart';
import 'package:whatsapp_clone/model/chat_contact.dart';
import 'package:whatsapp_clone/model/message.dart';
import 'package:whatsapp_clone/model/user_model.dart';

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  ),
);

class ChatRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  ChatRepository({required this.auth, required this.firestore});

  Stream<List<ChatContact>> getChatContacts() {
    return firestore
        .collection('user')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
          List<ChatContact> contacts = [];
          for (var document in event.docs) {
            var chatContact = ChatContact.fromMap(document.data());
            var userData = await firestore
                .collection('user')
                .doc(chatContact.contactId)
                .get();

            var user = UserModel.fromMap(userData.data()!);

            contacts.add(
              ChatContact(
                name: user.name,
                profilePic: user.profilePic,
                contactId: chatContact.contactId,
                timeSent: chatContact.timeSent,
                lastMessage: chatContact.lastMessage,
              ),
            );
          }
          return contacts;
        });
  }

  Stream<List<Message>> getChatStream(String recieverUserId) {
    return firestore
        .collection('user')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(recieverUserId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
          // TEMP DEBUG
          debugPrint('=== Firestore Raw Docs ===');
          debugPrint('Doc count: ${event.docs.length}');
          for (var doc in event.docs) {
            debugPrint('Doc data: ${doc.data()}');
          }
          debugPrint('==========================');

          List<Message> messages = [];
          for (var document in event.docs) {
            try {
              final data = document.data();

              // Handle both int and Timestamp for timeSent
              DateTime timeSent;
              final rawTime = data['timeSent'];
              if (rawTime is Timestamp) {
                timeSent = rawTime.toDate();
              } else if (rawTime is int) {
                timeSent = DateTime.fromMillisecondsSinceEpoch(rawTime);
              } else {
                timeSent = DateTime.now();
              }

              messages.add(
                Message(
                  senderId: data['senderId'] ?? '',
                  recieverId: data['recieverId'] ?? '',
                  text: data['text'] ?? '',
                  type: (data['type'] as String).toEnum(),
                  timeSent: timeSent,
                  messageId: data['messageId'] ?? '',
                  isSeen: data['isSeen'] ?? false,
                ),
              );
            } catch (e) {
              debugPrint('Error parsing message ${document.id}: $e');
              // Skip bad documents instead of crashing the whole stream
            }
          }
          return messages;
        });
  }

  void _sendDataToContactsSubcollection(
    UserModel senderUserData,
    UserModel recieverUserData,
    String text,
    DateTime timeSent,
    String recieverUserId,
  ) async {
    // user -> recieverUserId --> chat ---> current user id -->set data
    var recieverChatContact = ChatContact(
      name: senderUserData.name,
      profilePic: senderUserData.profilePic,
      contactId: senderUserData.uid,
      timeSent: timeSent,
      lastMessage: text,
    );
    await firestore
        .collection('user')
        .doc(recieverUserId)
        .collection('chats')
        .doc(senderUserData.uid)
        .set(recieverChatContact.toMap());
    // user -> current user id --> chat ---> recieverUserId  -->set data
    var senderChatContact = ChatContact(
      name: recieverUserData.name,
      profilePic: recieverUserData.profilePic,
      contactId: recieverUserData.uid,
      timeSent: timeSent,
      lastMessage: text,
    );
    await firestore
        .collection('user')
        .doc(senderUserData.uid)
        .collection('chats')
        .doc(recieverUserId)
        .set(senderChatContact.toMap());
  }

  void _saveMessageToMessageSubcollection({
    required String recieverUserId,
    required String senderUserId,
    required String text,
    required DateTime timeSent,
    required String messageId,
    required String username,
    required recieverUsername,
    required MessageEnum messageType,
  }) async {
    final message = Message(
      senderId: senderUserId,
      recieverId: recieverUserId,
      text: text,
      type: messageType,
      timeSent: timeSent,
      messageId: messageId,
      isSeen: false,
    );
    // user -> sender Id -> reciever id -> messages -> message Id
    await firestore
        .collection('user')
        .doc(senderUserId)
        .collection('chats')
        .doc(recieverUserId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    // user -> reciever Id -> sender id -> messages -> message Id
    await firestore
        .collection('user')
        .doc(recieverUserId)
        .collection('chats')
        .doc(senderUserId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());
  }

  void sendTextMessage({
    required BuildContext context,
    required String text,
    required String recieverUserId,
    required UserModel senderUser,
  }) async {
    try {
      var timeSent = DateTime.now();
      // UserModel recieverUserData;
      var userDataMap = await firestore
          .collection('user')
          .doc(recieverUserId)
          .get();

      var recieverUserData = UserModel.fromMap(userDataMap.data()!);
      var messageId = const Uuid().v1();
      _sendDataToContactsSubcollection(
        senderUser,
        recieverUserData,
        text,
        timeSent,
        recieverUserId,
      );

      _saveMessageToMessageSubcollection(
        recieverUserId: recieverUserId,
        senderUserId: senderUser.uid,
        text: text,
        timeSent: timeSent,
        messageId: messageId,
        username: senderUser.name,
        recieverUsername: recieverUserData.name,
        messageType: MessageEnum.text,
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void sendFileMessage({
    required BuildContext context,
    required File file,
    required String recieverUserId,
    required UserModel senderUserData,
    required Ref ref,
    required MessageEnum messageEnum,
  }) async {
    try {
      var timeSent = DateTime.now();
      var messageId = const Uuid().v1();

      var imageUrl = await ref
          .read(commonFirebaseStorageRepositoryProvider)
          .storeFileToFirebase(
            'chat / ${messageEnum.type}/${senderUserData.uid}/$recieverUserId/$messageId',
            file,
          );

      UserModel recieverUserData;
      var userDataMap = await firestore
          .collection('user')
          .doc(recieverUserId)
          .get();
      recieverUserData = UserModel.fromMap(userDataMap.data()!);

      String contactMsg;

      switch (messageEnum) {
        case MessageEnum.image:
          contactMsg = '📷Photo';
          break;
        case MessageEnum.video:
          contactMsg = '📽️ Video';
          break;
        case MessageEnum.audio:
          contactMsg = '🔊audio';
          break;
        case MessageEnum.gif:
          contactMsg = 'GIF';
          break;
        default:
          contactMsg = 'GIF';
          break;
      }
      _sendDataToContactsSubcollection(
        senderUserData,
        recieverUserData,
        contactMsg,
        timeSent,
        recieverUserId,
      );

      _saveMessageToMessageSubcollection(
        recieverUserId: recieverUserId,
        senderUserId: senderUserData.uid,
        text: imageUrl,
        timeSent: timeSent,
        messageId: messageId,
        username: senderUserData.name,
        recieverUsername: recieverUserData.name,
        messageType: messageEnum,
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
