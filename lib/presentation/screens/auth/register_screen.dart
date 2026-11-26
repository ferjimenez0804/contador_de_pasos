import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/biometric_service.dart';
import '../../../domain/entities/bio_method.dart';
import '../../widgets/bio_method_picker.dart';
import '../../widgets/body_data_fields.dart';
import '../../widgets/brutal.dart';
import '../../widgets/password_strength.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _userCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _pass2Ctl = TextEditingController();
  final BodyDataControllers _body = BodyDataControllers();
  bool _obscure = true;
  bool _biometric = false;
  BioMethod _method = BioMethod.fingerprint;
  BioCapabilities _caps = BioCapabilities.none;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    BiometricService.capabilities().then((c) {
      if (!mounted) return;
      setState(() {
        _caps = c;
        if (!c.fingerprint && c.face) _method = BioMethod.face;
      });
    });
  }

  /// Activa la biometría solo después de verificarla con el sensor elegido.
  Future<void> _enableBiometric(BioMethod method) async {
    final ok = await showBrutalDialog<bool>(
      context: context,
      icon: bioIcon(method),
      iconColor: method == BioMethod.face ? AppColors.lilac : AppColors.mint,
      title: method.title,
      content: Text(
        'Usaremos ${method == BioMethod.face ? 'el rostro' : 'la huella'} registrado en tu '
        'teléfono para proteger tu perfil. FitPulse no guarda ni accede a tus datos biométricos.',
      ),
      actions: (ctx) => [
        BrutalButton(
            label: 'Cancelar',
            compact: true,
            color: AppColors.card,
            onPressed: () => Navigator.pop(ctx, false)),
        BrutalButton(label: 'Verificar', compact: true, onPressed: () => Navigator.pop(ctx, true)),
      ],
    );
    if (ok != true || !mounted) return;
    final r = await BiometricService.authenticate(method, 'activar el acceso biométrico');
    if (!mounted) return;
    if (r.ok) {
      setState(() {
        _biometric = true;
        _method = method;
      });
      showBrutalSnack(context, '${r.message} Acceso activado.');
    } else {
      showBrutalSnack(context, r.message, error: true);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      showBrutalSnack(context, 'Revisa los campos marcados en rojo.', error: true);
      return;
    }
    setState(() => _loading = true);
    final err = await Di.auth.register(
      name: _nameCtl.text,
      username: _userCtl.text,
      password: _passCtl.text,
      biometric: _biometric,
      bioMethod: _method,
      body: _body.toBodyData(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      showBrutalSnack(context, err, error: true);
      return;
    }
    showBrutalSnack(context, 'Cuenta creada correctamente.');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _userCtl.dispose();
    _passCtl.dispose();
    _pass2Ctl.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BrutalScaffold(
      child: Column(
        children: [
          const BrutalTopBar(title: 'Registro'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenTitle('Crea tu\ncuenta', underline: AppColors.sun),
                    const SizedBox(height: 6),
                    const Text('Tus datos personalizan calorías, zancada e IMC.',
                        style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
                    const SectionLabel('01', 'Datos personales'),
                    BrutalField(
                      controller: _nameCtl,
                      label: 'Nombre completo',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.name,
                      inputFormatters: [Validators.nameFormatter],
                      maxLength: 50,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 14),
                    BrutalField(
                      controller: _userCtl,
                      label: 'Usuario',
                      icon: Icons.alternate_email_rounded,
                      inputFormatters: [Validators.usernameFormatter],
                      maxLength: 20,
                      validator: Validators.username,
                    ),
                    const SectionLabel('02', 'Datos corporales'),
                    BodyDataFields(c: _body, onChanged: () => setState(() {})),
                    const SectionLabel('03', 'Seguridad'),
                    BrutalField(
                      controller: _passCtl,
                      label: 'Contraseña',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      inputFormatters: [Validators.noSpaceFormatter],
                      maxLength: 32,
                      onChanged: (_) => setState(() {}),
                      suffix: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.ink),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 12),
                    PasswordStrengthMeter(password: _passCtl.text),
                    const SizedBox(height: 14),
                    BrutalField(
                      controller: _pass2Ctl,
                      label: 'Confirmar contraseña',
                      icon: Icons.lock_reset_rounded,
                      obscure: _obscure,
                      inputFormatters: [Validators.noSpaceFormatter],
                      maxLength: 32,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Confirma tu contraseña'
                          : (v != _passCtl.text ? 'Las contraseñas no coinciden' : null),
                    ),
                    const SectionLabel('04', 'Biometría'),
                    BrutalBox(
                      color: AppColors.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ACCESO BIOMÉTRICO',
                                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                                    Text('Entra sin escribir tu contraseña',
                                        style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                                  ],
                                ),
                              ),
                              BrutalSwitch(
                                value: _biometric,
                                onChanged: _caps.any
                                    ? (v) {
                                        if (v) {
                                          _enableBiometric(_method);
                                        } else {
                                          setState(() => _biometric = false);
                                        }
                                      }
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          BioMethodPicker(
                            caps: _caps,
                            selected: _method,
                            onSelect: (m) {
                              if (m == _method) return;
                              if (_biometric) {
                                _enableBiometric(m); // verifica el nuevo método
                              } else {
                                setState(() => _method = m);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    BrutalButton(
                      label: 'Crear cuenta',
                      icon: Icons.check_rounded,
                      color: AppColors.coral,
                      loading: _loading,
                      onPressed: _register,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
