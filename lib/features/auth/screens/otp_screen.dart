import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/features/auth/controller/auth_controller.dart';

class OtpScreen extends ConsumerWidget {
  static const String routeName = '/opt-screen';
  final String verificationId;
  const OtpScreen({Key? key, required this.verificationId}) : super(key: key);

  void verifyOTP(WidgetRef ref, BuildContext context, String userOTP) {
    ref
        .read(authControllerProvider)
        .verifyOTP(context, verificationId, userOTP);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const Icon(Icons.arrow_back_ios_new, size: 22),
        title: const Text(
          'Verify OTP',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Center(child: Text('We sent a OTP to Your phone Number')),
          SizedBox(
            width: size.width * 0.5,
            child: TextField(
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '- - - - - -',
                hintStyle: TextStyle(fontSize: 30),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                if (val.length == 6) {
                  verifyOTP(ref, context, val.trim());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
