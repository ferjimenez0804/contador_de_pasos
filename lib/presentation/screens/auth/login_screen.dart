import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/biometric_service.dart';
import '../../../domain/entities/bio_method.dart';
import '../../../domain/entities/user_account.dart';
import '../../widgets/brutal.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  BioCapabilities _caps = BioCapabilities.none;
  UserAccount? _bioUser;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final caps = await BiometricService.capabilities();
    final user = await Di.auth.lastBiometricUser();
    if (!mounted) return;
    setState(() {
      _caps = caps;
      _bioUser = user;
    });
    if (user != null && caps.supports(user.bioMethod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loginWithBio(user.bioMethod));
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _loginWithBio(BioMethod method) async {
    final user = _bioUser;
    if (user == null) return;
    final r = await BiometricService.authenticate(method, 'entrar a FitPulse');
    if (!mounted) return;
    if (r.ok) {
      await Di.auth.startSession(user);
      if (!mounted) return;
      showBrutalSnack(context, '¡Bienvenido, ${user.firstName}!');
      _goHome();
    } else {
      showBrutalSnack(context, r.message, error: true);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final acc = await Di.auth.login(_userCtl.text, _passCtl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (acc == null) {
      showBrutalSnack(context, 'Usuario o contraseña incorrectos.', error: true);
      return;
    }
    _goHome();
  }

  @override
  void dispose() {
    _userCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _bioUser;
    final methods = user == null ? <BioMethod>[] : _caps.methods;
    // El método preferido del usuario va primero.
    if (user != null && methods.remove(user.bioMethod)) methods.insert(0, user.bioMethod);

    return BrutalScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Portada con imagen
                Container(
                  height: 240,
                  clipBehavior: Clip.hardEdge,
                  decoration: brutalDecoration(color: AppColors.card, shadow: 6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/hero_login.jpg',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.2, -0.3),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.paper.withValues(alpha: 0.15),
                              AppColors.shadow.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: brutalDecoration(color: AppColors.lime, shadow: 3),
                          child: const Icon(Icons.directions_run_rounded, size: 30, color: AppColors.ink),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Transform.rotate(
                          angle: -0.05,
                          child: const Tag('Sensores + GPS', color: AppColors.paper),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text('FIT',
                    style: TextStyle(
                        fontSize: 72, fontWeight: FontWeight.w900, height: 0.9, letterSpacing: -3)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('PULSE',
                        style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            height: 0.9,
                            letterSpacing: -3)),
                    const SizedBox(width: 8),
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: brutalDecoration(color: AppColors.coral, shadow: 0, radius: 2),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Transform.rotate(
                  angle: -0.03,
                  child: const Tag('Muévete · Mide · Supérate', color: AppColors.sun),
                ),
                const SizedBox(height: 34),
                BrutalField(
                  controller: _userCtl,
                  label: 'Usuario',
                  icon: Icons.alternate_email_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu usuario' : null,
                ),
                const SizedBox(height: 14),
                BrutalField(
                  controller: _passCtl,
                  label: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.ink),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                ),
                const SizedBox(height: 22),
                BrutalButton(
                  label: 'Entrar',
                  icon: Icons.arrow_forward_rounded,
                  loading: _loading,
                  onPressed: _login,
                ),
                if (user != null && methods.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: Container(height: kBorder, color: AppColors.ink)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('O ENTRA COMO ${user.firstName.toUpperCase()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                      ),
                      Expanded(child: Container(height: kBorder, color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var i = 0; i < methods.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: BrutalButton(
                            label: methods[i].label,
                            icon: bioIcon(methods[i]),
                            color: methods[i] == BioMethod.face ? AppColors.lilac : AppColors.mint,
                            onPressed: () => _loginWithBio(methods[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 26),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.ink, width: kBorder)),
                      ),
                      child: const Text('¿SIN CUENTA? CREA UNA →',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
