import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_state.dart';

/// Layar masuk: latar gelap + sheet putih (bukan kartu mengambang di tengah).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthState>();
    final ok = await auth.login(_username.text, _password.text);

    if (!ok && mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      backgroundColor: AppColors.shell,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                          alignment: Alignment.center,
                          child: Text('MP',
                              style: appText(size: 13, weight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 10),
                        Text('Mann Plus Advertising',
                            style: appText(size: 13, weight: FontWeight.w600, color: const Color(0xFFCBD5E1))),
                      ],
                    ),
                    const Spacer(),
                    Text('SISTEM PENGGAJIAN',
                        style: appText(size: 10, weight: FontWeight.w700, color: const Color(0xFF818CF8), letterSpacing: 1.6)),
                    const SizedBox(height: 10),
                    Text('Slip gaji\ndi tangan lo.',
                        style: appText(size: 34, weight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -1)),
                    const SizedBox(height: 10),
                    Text(
                      'Masuk pakai akun yang dikasih admin bengkel. Slip terbit dan status pembayaran langsung kelihatan.',
                      style: appText(size: 13, color: const Color(0xFF94A3B8), height: 1.55),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('USERNAME', style: labelText(color: AppColors.inkMuted)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _username,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      style: appText(size: 14),
                      decoration: const InputDecoration(
                        hintText: 'Masukkan username',
                        prefixIcon: Icon(Icons.person_outline, size: 18, color: AppColors.muted),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Username wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    Text('PASSWORD', style: labelText(color: AppColors.inkMuted)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      style: appText(size: 14),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18, color: AppColors.muted),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Password wajib diisi' : null,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: auth.submitting ? null : _submit,
                      child: auth.submitting
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Masuk'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Lupa password? Hubungi admin bengkel',
                        style: appText(size: 12, weight: FontWeight.w600, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
