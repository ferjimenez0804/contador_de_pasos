import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/workout.dart';
import '../../widgets/brutal.dart';
import '../auth/login_screen.dart';
import '../workout/workout_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  List<Workout> _workouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Di.auth.current;
    if (user == null) return;
    final list = await Di.workouts.load(user.username);
    if (!mounted) return;
    setState(() {
      _workouts = list;
      _loading = false;
    });
  }

  Future<void> _startWorkout() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkoutScreen()));
    _load();
  }

  void _logout() {
    Di.auth.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Di.auth.current;
    if (user == null) return const LoginScreen();

    final pages = <Widget>[
      DashboardTab(user: user, workouts: _workouts, onStart: _startWorkout),
      HistoryTab(workouts: _workouts, onChanged: _load),
      ProfileTab(
        workouts: _workouts,
        onLogout: _logout,
        onProfileChanged: () => setState(() {}),
      ),
    ];

    return BrutalScaffold(
      bottom: _BottomBar(index: _tab, onSelect: (i) => setState(() => _tab = i)),
      child: _loading ? const Center(child: CircularProgressIndicator()) : pages[_tab],
    );
  }
}

/// Barra inferior propia: la pestaña activa se convierte en un bloque con texto.
class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const _BottomBar({required this.index, required this.onSelect});

  static const _items = [
    (Icons.bolt_rounded, 'Hoy', AppColors.lime),
    (Icons.view_agenda_rounded, 'Historial', AppColors.sun),
    (Icons.person_rounded, 'Perfil', AppColors.lilac),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  flex: i == index ? 2 : 1,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: i == index
                          ? brutalDecoration(color: _items[i].$3, shadow: 3)
                          : const BoxDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_items[i].$1, color: AppColors.ink, size: 24),
                          if (i == index) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _items[i].$2.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
