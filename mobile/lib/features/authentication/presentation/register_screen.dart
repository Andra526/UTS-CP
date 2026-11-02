import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_message.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../gym_selection/data/gym_repository.dart';
import '../../gym_selection/domain/gym.dart';
import '../data/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Admin Gym tidak bisa mendaftar sendiri (dibuat oleh sistem/admin pusat).
  static const String _memberLabel = 'User / Member';
  static const String _trainerLabel = 'Personal Trainer (PT)';
  final List<String> roles = [_memberLabel, _trainerLabel];

  String selectedRole = _memberLabel;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  final _authRepo = AuthRepository();
  final _gymRepo = GymRepository();

  List<Gym> _gyms = [];
  String? _selectedGymId;
  bool _loadingGyms = false;
  bool _submitting = false;
  String? _error;

  bool get _isTrainer => selectedRole == _trainerLabel;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadGyms() async {
    if (_gyms.isNotEmpty || _loadingGyms) return;
    setState(() => _loadingGyms = true);
    try {
      final gyms = await _gymRepo.list();
      if (!mounted) return;
      setState(() {
        _gyms = gyms;
        _selectedGymId = gyms.isNotEmpty ? gyms.first.id : null;
        _loadingGyms = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGyms = false;
        _error = errorMessage(e);
      });
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 2 ||
        !_email.text.contains('@') ||
        _password.text.length < 6) {
      setState(() => _error = 'Isi nama, email yang valid, dan password min. 6 karakter.');
      return;
    }
    if (_isTrainer && _selectedGymId == null) {
      setState(() => _error = 'Pilih cabang gym tempat Anda bertugas.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final user = await _authRepo.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
        role: _isTrainer ? Roles.trainer : Roles.member,
        gymId: _isTrainer ? _selectedGymId : null,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.homeFor(user.role),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Akun',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Buat akun untuk mulai perjalanan fitness kamu.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              const Text(
                'Daftar Sebagai',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _dropdownBox(
                DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                  items: roles
                      .map(
                        (role) => DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => selectedRole = value);
                    if (value == _trainerLabel) _loadGyms();
                  },
                ),
              ),
              if (_isTrainer) ...[
                const SizedBox(height: 16),
                const Text(
                  'Cabang Gym Tempat Bertugas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _loadingGyms
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator(color: Colors.black)),
                      )
                    : _dropdownBox(
                        DropdownButton<String>(
                          value: _selectedGymId,
                          isExpanded: true,
                          hint: const Text('Pilih cabang'),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                          items: _gyms
                              .map(
                                (g) => DropdownMenuItem<String>(
                                  value: g.id,
                                  child: Text(
                                    g.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) =>
                              setState(() => _selectedGymId = value),
                        ),
                      ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                controller: _name,
                label: 'Nama Lengkap',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phone,
                label: 'No. HP (opsional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _password,
                label: 'Password (min. 6 karakter)',
                icon: Icons.lock_outline,
                obscure: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              AppButton(label: 'Daftar', loading: _submitting, onPressed: _submit),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownBox(Widget dropdown) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(child: dropdown),
    );
  }
}
