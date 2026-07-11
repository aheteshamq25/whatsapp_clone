import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/features/chats/screens/mobile_chat_screen.dart';
import 'package:whatsapp_clone/commons/utils/utils.dart';
import 'package:whatsapp_clone/model/user_model.dart';

final selectContactRepositoryProvider = Provider(
  (ref) => SelectContactRepository(firestore: FirebaseFirestore.instance),
);

class SelectContactRepository {
  final FirebaseFirestore firestore;

  SelectContactRepository({required this.firestore});

  Future<List<Contact>> getContacts() async {
    List<Contact> contacts = [];
    try {
      // Request permissions
      final status = await FlutterContacts.permissions.request(
        PermissionType.readWrite,
      );
      if (status == PermissionStatus.granted) {
        // Get all contacts (fast - defaults to IDs and display names only)
        contacts = await FlutterContacts.getAll(
          properties: {ContactProperty.photoThumbnail, ContactProperty.phone},
        );

        // Get a specific contact with all properties
        // Contact? contact = await FlutterContacts.get(
        //   contacts.first.id!,
        //   properties: ContactProperties.all,
        // );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return contacts;
  }

  void selectContact(Contact selectedContact, BuildContext context) async {
    try {
      var userCollection = await firestore.collection('user').get();
      bool isFound = false;

      for (var document in userCollection.docs) {
        var userData = UserModel.fromMap(document.data());
        String selectedPhoneNum = selectedContact.phones[0].number.replaceAll(
          ' ',
          '',
        );
        if (selectedPhoneNum == userData.phoneNumber) {
          isFound = true;
          Navigator.pushNamed(
            context,
            MobileChatScreen.routeName,
            arguments: {'name': userData.name, 'uid': userData.uid},
          );
        }
      }

      if (!isFound) {
        showSnackBar(
          context: context,
          content: 'This number does not exist on this app.',
        );
      }
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
