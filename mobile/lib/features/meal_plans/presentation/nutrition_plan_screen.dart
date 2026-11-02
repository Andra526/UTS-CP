import 'package:flutter/material.dart';

import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../authentication/presentation/session_controller.dart';
import '../data/meal_plan_repository.dart';
import '../domain/meal_plan.dart';
import 'meal_tile.dart';

/// Pola makan MEMBER yang sedang login (baca saja).
/// Data diambil dari /meal-plans/me, jadi hanya berisi menu milik akun ini:
/// login sebagai Andra -> menu Andra, login sebagai Budi -> menu Budi.
/// Menu hanya bisa diubah oleh PT (lihat PtClientNutritionScreen).
class NutritionPlanScreen extends StatelessWidget {
  const NutritionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = MealPlanRepository();
    final name = session.user?.name ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Pola Makan Saya',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: AsyncBuilder<MealPlan>(
        loader: repo.mine,
        builder: (context, plan, reload) {
          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                if (name.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Menu harian untuk $name',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ),
                if (plan.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'Belum ada pola makan',
                      subtitle:
                          'Personal Trainer Anda belum menyusun menu. Booking sesi dengan PT untuk mendapatkannya.',
                    ),
                  )
                else ...[
                  MealSummary(plan: plan),
                  const SizedBox(height: 16),
                  for (final item in plan.items) MealTile(item: item),
                  if (plan.items.first.trainerName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Disusun oleh ${plan.items.first.trainerName}. Tarik ke bawah untuk memuat pembaruan.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
