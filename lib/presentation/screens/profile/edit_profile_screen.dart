import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/body_data_fields.dart';
import '../../widgets/brutal.dart';

/// Edita peso, estatura, edad, sexo y meta diaria del usuario actual.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BodyDataControllers _body;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = Di.auth.current!;
    _body = BodyDataControllers(
      weightKg: u.weightKg?.round(),
      heightCm: u.heightCm,
      age: u.age,
      sex: u.sex,
      dailyGoal: u.dailyGoal,
    );
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      showBrutalSnack(context, 'Revisa los campos marcados en rojo.', error: true);
      return;
    }
    setState(() => _saving = true);
    await Di.auth.updateProfile(_body.toBodyData());
    if (!mounted) return;
    showBrutalSnack(context, 'Datos actualizados.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BrutalScaffold(
      child: Column(
        children: [
          const BrutalTopBar(title: 'Mis datos'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenTitle('Ajusta tu\ncuerpo', underline: AppColors.mint),
                    const SizedBox(height: 6),
                    const Text(
                      'Se usan para calcular tus calorías, la longitud de tu zancada y tu IMC.',
                      style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 22),
                    BodyDataFields(c: _body, onChanged: () => setState(() {})),
                    const SizedBox(height: 26),
                    BrutalButton(
                      label: 'Guardar cambios',
                      icon: Icons.save_rounded,
                      loading: _saving,
                      onPressed: _save,
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
