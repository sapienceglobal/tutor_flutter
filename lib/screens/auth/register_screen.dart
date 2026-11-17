import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/sapience_ui.dart';
import '../home/home_screen.dart';
import 'pending_approval_hub_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteController = TextEditingController();
  final _subjectsController = TextEditingController();
  final _titleController = TextEditingController();
  final _requestMessageController = TextEditingController();
  final _instituteSearchController = TextEditingController();
  final _tutorSearchController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _verifyWithOtp = false;

  String _selectedRole = 'student';
  // Student: 'institute' | 'tutors' | 'both' | 'invite'
  // Tutor: 'private_studio' | 'institute' | 'invite'
  String _connectionMode = 'institute';

  Timer? _instDebounce;
  Timer? _tutorDebounce;
  bool _loadingInstitutes = false;
  bool _loadingTutors = false;
  List<Map<String, dynamic>> _institutes = [];
  List<Map<String, dynamic>> _tutors = [];

  Map<String, dynamic>? _selectedInstitute;
  final List<Map<String, dynamic>> _selectedTutors = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchInstitutes('');
      _searchTutors('');
    });
  }

  @override
  void dispose() {
    _instDebounce?.cancel();
    _tutorDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteController.dispose();
    _subjectsController.dispose();
    _titleController.dispose();
    _requestMessageController.dispose();
    _instituteSearchController.dispose();
    _tutorSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchInstitutes(String query) async {
    setState(() => _loadingInstitutes = true);
    try {
      final results = await AuthService.searchPublicInstitutes(search: query);
      if (!mounted) return;
      setState(() {
        _institutes = results;
        _loadingInstitutes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingInstitutes = false);
    }
  }

  Future<void> _searchTutors(String query) async {
    setState(() => _loadingTutors = true);
    try {
      final results = await AuthService.searchPublicTutors(search: query);
      if (!mounted) return;
      setState(() {
        _tutors = results;
        _loadingTutors = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTutors = false);
    }
  }

  void _onInstituteSearchChanged(String val) {
    _instDebounce?.cancel();
    _instDebounce = Timer(const Duration(milliseconds: 320), () {
      _searchInstitutes(val);
    });
  }

  void _onTutorSearchChanged(String val) {
    _tutorDebounce?.cancel();
    _tutorDebounce = Timer(const Duration(milliseconds: 320), () {
      _searchTutors(val);
    });
  }

  void _selectRole(String role) {
    if (_selectedRole == role) return;
    setState(() {
      _selectedRole = role;
      if (_connectionMode != 'invite') {
        _connectionMode = role == 'tutor' ? 'private_studio' : 'institute';
      }
      if (role == 'tutor') {
        _selectedTutors.clear();
      }
    });
  }

  void _toggleTutor(Map<String, dynamic> tutor) {
    final id = (tutor['tutorId'] ?? tutor['_id'] ?? '').toString();
    setState(() {
      final idx = _selectedTutors.indexWhere(
        (t) => (t['tutorId'] ?? t['_id'] ?? '').toString() == id,
      );
      if (idx >= 0) {
        _selectedTutors.removeAt(idx);
      } else {
        _selectedTutors.add(tutor);
      }
    });
  }

  bool get _needsInstitutePicker =>
      _connectionMode == 'institute' || _connectionMode == 'both';

  bool get _needsTutorPicker =>
      _selectedRole == 'student' &&
      (_connectionMode == 'tutors' || _connectionMode == 'both');

  String? _validateSelection() {
    if (_connectionMode == 'invite') {
      if (_inviteController.text.trim().isEmpty) {
        return 'Please enter your invite code or token.';
      }
      return null;
    }

    if (_selectedRole == 'student') {
      if (_connectionMode == 'institute' && _selectedInstitute == null) {
        return 'Please select an Institute to send your admission request.';
      }
      if (_connectionMode == 'tutors' && _selectedTutors.isEmpty) {
        return 'Please select at least one Private Tutor to send a request.';
      }
      if (_connectionMode == 'both' &&
          _selectedInstitute == null &&
          _selectedTutors.isEmpty) {
        return 'Please select an Institute or at least one Private Tutor.';
      }
    } else if (_selectedRole == 'tutor' &&
        _connectionMode == 'institute' &&
        _selectedInstitute == null) {
      return 'Select the Institute you want to join, or pick Start Private Studio.';
    }
    return null;
  }

  Future<void> _completePostAuthNavigation(AuthProvider authProvider) async {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    if (authProvider.user != null) {
      await workspaceProvider.applyBootstrap(
        authProvider.workspaceBootstrap,
        userId: authProvider.user!.id,
        role: authProvider.user!.role,
      );
      subscriptionProvider.syncWithWorkspace(
        userMap: authProvider.rawUser ?? authProvider.user!.toJson(),
        workspace: workspaceProvider,
      );
    }

    if (!mounted) return;
    final Widget target = workspaceProvider.hasActiveWorkspace
        ? const HomeScreen()
        : const PendingApprovalHubScreen();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => target),
      (route) => false,
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final selectionError = _validateSelection();
    if (selectionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(selectionError), backgroundColor: AppColors.error),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? instituteId = _needsInstitutePicker && _selectedInstitute != null
        ? (_selectedInstitute!['_id'] ?? _selectedInstitute!['id']).toString()
        : null;
    final List<String>? tutorIds = _needsTutorPicker && _selectedTutors.isNotEmpty
        ? _selectedTutors
            .map((t) => (t['tutorId'] ?? t['_id']).toString())
            .toList()
        : null;
    final String? inviteToken = _connectionMode == 'invite'
        ? _inviteController.text.trim()
        : null;

    if (_verifyWithOtp) {
      final purpose = inviteToken != null
          ? 'invite-registration'
          : 'email-verification';
      final otpSent = await authProvider.sendOtp(
        email: _emailController.text.trim(),
        purpose: purpose,
      );
      if (!mounted) return;
      if (!otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to send OTP'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final otpCode = await _showOtpDialog(
        email: _emailController.text.trim(),
        purpose: purpose,
      );
      if (otpCode == null || otpCode.isEmpty || !mounted) return;

      final verified = await authProvider.verifyOtpAndRegister(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        otp: otpCode,
        role: _selectedRole,
        purpose: purpose,
        instituteId: instituteId,
        tutorIds: tutorIds,
        inviteToken: inviteToken,
        requestMessage: _requestMessageController.text.trim(),
        subjects: _subjectsController.text.trim(),
        title: _selectedRole == 'tutor' ? _titleController.text.trim() : null,
      );
      if (!mounted) return;
      if (verified) {
        await _completePostAuthNavigation(authProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'OTP verification failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      instituteId: instituteId,
      tutorIds: tutorIds,
      inviteToken: inviteToken,
      requestMessage: _requestMessageController.text.trim(),
      subjects: _subjectsController.text.trim(),
      title: _selectedRole == 'tutor' ? _titleController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      await _completePostAuthNavigation(authProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<String?> _showOtpDialog({
    required String email,
    required String purpose,
  }) {
    final otpCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Verify Your Email',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6-digit verification code sent to $email',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '6-Digit OTP',
                prefixIcon: Icon(Icons.mark_email_read_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.sendOtp(email: email, purpose: purpose);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('OTP resent to your email')),
                );
              }
            },
            child: const Text('Resend OTP'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final code = otpCtrl.text.trim();
              if (code.length < 4) return;
              Navigator.of(ctx).pop(code);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  List<_ModeOption> get _modeOptions {
    if (_selectedRole == 'tutor') {
      return const [
        _ModeOption('private_studio', 'Private Studio', Icons.co_present_rounded),
        _ModeOption('institute', 'Join Institute', Icons.apartment_rounded),
        _ModeOption('invite', 'Invite Code', Icons.key_rounded),
      ];
    }
    return const [
      _ModeOption('institute', 'Institute', Icons.apartment_rounded),
      _ModeOption('tutors', 'Private Tutors', Icons.person_search_rounded),
      _ModeOption('both', 'Both', Icons.layers_rounded),
      _ModeOption('invite', 'Invite Code', Icons.key_rounded),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const SapienceHeader(title: 'Create Account'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SapienceCard(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 22,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Select Account Role',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildRoleOption(
                                      role: 'student',
                                      label: 'Student',
                                      subtitle: '100% free access',
                                      icon: Icons.school_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildRoleOption(
                                      role: 'tutor',
                                      label: 'Educator',
                                      subtitle: 'Studio & Institute',
                                      icon: Icons.co_present_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Connect Workspace',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _modeOptions.map((m) {
                                  final selected = _connectionMode == m.id;
                                  return ChoiceChip(
                                    avatar: Icon(
                                      m.icon,
                                      size: 16,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                    label: Text(
                                      m.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textMain,
                                      ),
                                    ),
                                    selected: selected,
                                    selectedColor: AppColors.primary,
                                    backgroundColor: AppColors.innerSurface,
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.cardBorder,
                                    ),
                                    onSelected: (_) {
                                      setState(() => _connectionMode = m.id);
                                    },
                                  );
                                }).toList(),
                              ),
                              if (_selectedRole == 'tutor' &&
                                  _connectionMode == 'private_studio') ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Starts your Private Tuition Studio immediately on the Free Starter Plan. Accept private student requests, create free/offline/paid courses, and connect institutes later.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_connectionMode == 'invite') ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _inviteController,
                                  decoration: const InputDecoration(
                                    labelText: 'Institute Invite Code / Token',
                                    prefixIcon: Icon(Icons.key_rounded, size: 20),
                                  ),
                                ),
                              ],
                              if (_needsInstitutePicker) ...[
                                const SizedBox(height: 14),
                                _buildInstituteSelector(),
                              ],
                              if (_needsTutorPicker) ...[
                                const SizedBox(height: 14),
                                _buildTutorMultiSelector(),
                              ],
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon:
                                      Icon(Icons.person_outline_rounded, size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().length < 2) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon:
                                      Icon(Icons.email_outlined, size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon:
                                      Icon(Icons.phone_outlined, size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().length < 7) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              if (_selectedRole == 'tutor') ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Teaching Headline (Optional)',
                                    hintText: 'e.g. NEET Biology & Organic Chemistry',
                                    prefixIcon:
                                        Icon(Icons.badge_outlined, size: 20),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _subjectsController,
                                decoration: InputDecoration(
                                  labelText: _selectedRole == 'tutor'
                                      ? 'Subjects Taught (comma-separated)'
                                      : 'Subjects Needed (Optional)',
                                  hintText: 'e.g. Mathematics, Physics, Hindi',
                                  prefixIcon: const Icon(
                                    Icons.menu_book_outlined,
                                    size: 20,
                                  ),
                                ),
                              ),
                              if (_connectionMode != 'invite' &&
                                  (_needsInstitutePicker || _needsTutorPicker)) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _requestMessageController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Note for Institute / Tutor (Optional)',
                                    hintText: 'Class, exam goal, or batch timing',
                                    prefixIcon:
                                        Icon(Icons.chat_bubble_outline, size: 20),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                value: _verifyWithOtp,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: AppColors.primary,
                                title: const Text(
                                  'Verify email address with 6-digit OTP',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                onChanged: (val) => setState(
                                  () => _verifyWithOtp = val ?? false,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  if (authProvider.isLoading) {
                                    return Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: AppThemeDesign.greenToBlueGradient,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }
                                  return SapienceButton(
                                    label: _verifyWithOtp
                                        ? 'Send OTP & Create Account'
                                        : 'Create Account',
                                    trailingIcon: Icons.arrow_forward_rounded,
                                    variant: SapienceButtonVariant.greenToBlue,
                                    height: 48,
                                    onTap: _register,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildInstituteSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.innerSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment_rounded, size: 17, color: AppColors.primary),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Search & Select Institute',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              if (_selectedInstitute != null)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => setState(() => _selectedInstitute = null),
                  child: const Text('Clear', style: TextStyle(fontSize: 11.5)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _instituteSearchController,
            onChanged: _onInstituteSearchChanged,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Search institute name or city...',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingInstitutes)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_institutes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'No matching institutes found.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 165),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _institutes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, idx) {
                  final inst = _institutes[idx];
                  final id = (inst['_id'] ?? inst['id'] ?? '').toString();
                  final isSelected =
                      (_selectedInstitute?['_id'] ?? _selectedInstitute?['id'])
                              ?.toString() ==
                          id;
                  final discovery = inst['discovery'] is Map
                      ? inst['discovery'] as Map
                      : const {};
                  final city = (discovery['city'] ?? '').toString();
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedInstitute = inst),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primarySoft : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inst['name']?.toString() ?? 'Institute',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMain,
                                  ),
                                ),
                                if (city.isNotEmpty)
                                  Text(
                                    city,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTutorMultiSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.innerSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search_rounded, size: 17, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Select Private Tutor(s) (${_selectedTutors.length} picked)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedTutors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedTutors.map((t) {
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(
                    t['name']?.toString() ?? 'Tutor',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => _toggleTutor(t),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _tutorSearchController,
            onChanged: _onTutorSearchChanged,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Search tutor by name or subject...',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingTutors)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_tutors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'No matching private tutors found.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 185),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _tutors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, idx) {
                  final tutor = _tutors[idx];
                  final id = (tutor['tutorId'] ?? tutor['_id'] ?? '').toString();
                  final isSelected = _selectedTutors.any(
                    (t) => (t['tutorId'] ?? t['_id'] ?? '').toString() == id,
                  );
                  final subjectsList = (tutor['subjects'] as List?)
                          ?.map((e) => e.toString())
                          .take(3)
                          .join(', ') ??
                      '';
                  final subtitle = (tutor['headline'] ?? tutor['title'] ?? '').toString();

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _toggleTutor(tutor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primarySoft : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tutor['name']?.toString() ?? 'Private Tutor',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMain,
                                  ),
                                ),
                                if (subjectsList.isNotEmpty || subtitle.isNotEmpty)
                                  Text(
                                    subjectsList.isNotEmpty ? subjectsList : subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required String role,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.innerSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.textMain,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption {
  final String id;
  final String label;
  final IconData icon;
  const _ModeOption(this.id, this.label, this.icon);
}
