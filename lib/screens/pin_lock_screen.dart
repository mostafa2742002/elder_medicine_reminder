import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinLockScreen extends StatefulWidget {
  final String correctPin;

  const PinLockScreen({
    super.key,
    required this.correctPin,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final pinController = TextEditingController();
  final pinFocusNode = FocusNode();

  bool hasError = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    pinController.dispose();
    pinFocusNode.dispose();
    super.dispose();
  }

  void verifyPin() {
    final enteredPin = pinController.text.trim();

    if (enteredPin == widget.correctPin) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      hasError = true;
      pinController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'الرقم السري غير صحيح',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );

    pinFocusNode.requestFocus();
  }

  void cancel() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? Colors.red : Colors.green.shade300;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'دخول مقدم الرعاية',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 96,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'هذه المنطقة مخصصة لمقدم الرعاية',
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'أدخل الرقم السري لإضافة أو تعديل أو حذف الأدوية.',
                        style: TextStyle(
                          fontSize: 21,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: pinController,
                        focusNode: pinFocusNode,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'الرقم السري',
                          hintText: '****',
                          counterText: '',
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: borderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: borderColor,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.password),
                        ),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        onSubmitted: (_) {
                          verifyPin();
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'الرقم الافتراضي حاليًا: 1234',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 70,
                        child: FilledButton.icon(
                          onPressed: verifyPin,
                          icon: const Icon(
                            Icons.check_circle,
                            size: 30,
                          ),
                          label: const Text(
                            'دخول',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 58,
                        child: OutlinedButton.icon(
                          onPressed: cancel,
                          icon: const Icon(Icons.close),
                          label: const Text(
                            'إلغاء',
                            style: TextStyle(fontSize: 21),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}