import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/domain/activity.dart';
import '../../activity/presentation/activity_tile.dart';
import '../../activity/presentation/progress_screen.dart';
import '../../authentication/presentation/session_controller.dart';
import '../../session_packages/data/session_package_repository.dart';
import '../../session_packages/domain/session_package.dart';
import '../../session_packages/presentation/session_quota_card.dart';
import '../../bookings/presentation/my_bookings_screen.dart';
import '../../exercises/presentation/exercises_screen.dart';
import '../../gym_selection/data/gym_repository.dart';
import '../../gym_selection/domain/gym.dart';
import '../../meal_plans/presentation/nutrition_plan_screen.dart';
import '../../memberships/data/membership_repository.dart';
import '../../memberships/domain/membership.dart';
import '../../memberships/presentation/payment_dialog.dart';
import '../../personal_trainers/presentation/trainer_list_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  final _gymRepo = GymRepository();
  final _membershipRepo = MembershipRepository();
  final _activityRepo = ActivityRepository();
  final _packageRepo = SessionPackageRepository();
  List<SessionPackage> _packages = [];

  List<Gym> _gyms = [];
  Gym? _selected;
  Membership? _active;
  List<ActivityItem> _activities = [];
  bool _loading = true;
  String? _error;

  // Hitung mundur membership
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gyms = await _gymRepo.list();
      final active = await _membershipRepo.active();
      // Log aktivitas bersifat pelengkap: bila gagal, Beranda tetap tampil.
      List<ActivityItem> activities = [];
      try {
        activities = (await _activityRepo.mine()).items.take(5).toList();
      } catch (_) {}
      List<SessionPackage> packages = [];
      try {
        packages = await _packageRepo.mine();
      } catch (_) {}
      if (!mounted) return;

      Gym? selected;
      final keepId = _selected?.id ?? active?.gymId;
      if (keepId != null) {
        for (final g in gyms) {
          if (g.id == keepId) selected = g;
        }
      }
      selected ??= gyms.isNotEmpty ? gyms.first : null;

      setState(() {
        _gyms = gyms;
        _selected = selected;
        _active = active;
        _activities = activities;
        _packages = packages;
        _remainingSeconds = active?.remainingSeconds ?? 0;
        _loading = false;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errorMessage(e);
      });
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    if (_active == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _load(); // masa aktif habis -> muat ulang status
      }
    });
  }

  Future<void> _pay(GymPlan plan) async {
    final gym = _selected;
    if (gym == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showPaymentDialog(context, plan: plan, gymName: gym.name);
    if (!ok) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Pembayaran berhasil! Membership ${plan.name} aktif.')),
    );
    if (mounted) _load();
  }

  void _soon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature akan hadir di pembaruan berikutnya.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AppLoading());
    if (_error != null) {
      return Scaffold(body: AppErrorView(message: _error!, onRetry: _load));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedBuilder(
                            animation: session,
                            builder: (context, child) {
                              final name = firstName(session.user?.name ?? '');
                              return Text(
                                name.isEmpty ? 'Halo 👋' : 'Halo, $name 👋',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Semangat latihan hari ini!',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                        onPressed: () => _soon('Notifikasi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dropdown Lokasi Gym
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selected?.id,
                            isExpanded: true,
                            hint: const Text('Belum ada cabang'),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                            items: _gyms
                                .map(
                                  (g) => DropdownMenuItem<String>(
                                    value: g.id,
                                    child: Text(
                                      g.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? id) {
                              if (id == null) return;
                              setState(() {
                                _selected = _gyms.firstWhere((g) => g.id == id);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // KARTU MEMBERSHIP / STATUS AKTIF DENGAN TIMER BERJALAN
                _active != null ? _activeMembershipCard(_active!) : _plansCard(),
                const SizedBox(height: 16),

                // KUOTA SESI PT (Sisa sesi: x dari 8)
                _quotaBox(),

                // LOG AKTIVITAS TERBARU (di bawah kartu membership)
                _activityBox(),
                const SizedBox(height: 24),

                // Grid Menu Utama
                Row(
                  children: [
                    _buildFeatureCard(
                      Icons.fitness_center,
                      'Program Latihan',
                      Colors.blue.shade50,
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExercisesScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildFeatureCard(
                      Icons.restaurant_menu,
                      'Pola Makan',
                      Colors.green.shade50,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NutritionPlanScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFeatureCard(
                      Icons.person_add_alt_1_outlined,
                      'Pilih PT',
                      Colors.red.shade50,
                      Colors.red,
                      () {
                        final gym = _selected;
                        if (gym == null) {
                          _soon('Daftar PT');
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TrainerListScreen(gymId: gym.id, gymName: gym.name),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildFeatureCard(
                      Icons.chat_bubble_outline,
                      'Chat AI',
                      Colors.purple.shade50,
                      Colors.purple,
                      () => _soon('Chat AI'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFeatureCard(
                      Icons.event_note_outlined,
                      'Sesi Saya',
                      Colors.orange.shade50,
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeMembershipCard(Membership m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Membership Aktif',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  m.planName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(m.gymName, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
          const Text('Waktu Berakhir:', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            formatCountdown(_remainingSeconds),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quotaBox() {
    if (_packages.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_available_outlined, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Booking PT dan dapatkan paket 8 sesi latihan.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          for (final p in _packages) ...[
            SessionQuotaCard(pkg: p, compact: true),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _activityBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              if (_activities.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProgressScreen()),
                  ),
                  child: const Text('Lihat semua', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          if (_activities.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                'Belum ada aktivitas. Beli membership, booking PT, atau mulai latihan — riwayatnya muncul di sini.',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
            )
          else
            for (var i = 0; i < _activities.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
              ActivityTile(item: _activities[i]),
            ],
        ],
      ),
    );
  }

  Widget _plansCard() {
    // Tampilkan paket bulanan & tahunan (paket harian ada di halaman detail gym)
    final plans = (_selected?.plans ?? <GymPlan>[])
        .where((p) => p.durationDays >= 28)
        .take(2)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Paket Membership & Bayar',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (plans.isEmpty)
            const Text(
              'Belum ada paket untuk cabang ini.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            Row(
              children: [
                for (var i = 0; i < plans.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _buildMembershipCard(plans[i])),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(GymPlan plan) {
    final isPopular = plan.isPopular;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPopular ? Colors.white : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: isPopular ? Border.all(color: Colors.amber, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Terlaris',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          Text(
            plan.name,
            style: TextStyle(
              color: isPopular ? Colors.black87 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(plan.price),
            style: TextStyle(
              color: isPopular ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            plan.periodLabel,
            style: TextStyle(
              color: isPopular ? Colors.grey.shade600 : Colors.white54,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? Colors.black : Colors.white,
                foregroundColor: isPopular ? Colors.white : Colors.black,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _pay(plan),
              child: const Text('Bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
