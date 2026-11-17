import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../services/payout_service.dart';
import '../../utils/constants.dart';
import '../../widgets/audience_selector.dart';
import 'earnings/tutor_earnings_screen.dart';

class EditCourseScreen extends StatefulWidget {
  final CourseModel course;

  const EditCourseScreen({super.key, required this.course});

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _offlineInstructionsController;
  late TextEditingController _durationController;

  String? _selectedCategoryId; // ✅ Changed to ID instead of object
  String _selectedLevel = 'beginner';
  String _selectedLanguage = 'English';
  bool _isFree = true;
  String _pricingMode = 'offline';
  String _payoutVerificationStatus = 'not_configured';

  String _audienceScope = 'institute';
  List<String> _audienceBatchIds = [];
  List<String> _audienceStudentIds = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _descriptionController = TextEditingController(
      text: widget.course.description,
    );
    _priceController = TextEditingController(
      text: widget.course.price.toString(),
    );
    _offlineInstructionsController = TextEditingController(
      text: widget.course.offlinePaymentInstructions,
    );
    _durationController = TextEditingController(
      text: widget.course.duration.toString(),
    );

    _selectedLevel = widget.course.level;
    _selectedLanguage = widget.course.language;
    _isFree = widget.course.isFree;
    _pricingMode = widget.course.pricingMode == 'online' ? 'online' : 'offline';
    _selectedCategoryId = widget.course.category.id; // ✅ Store ID

    final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
    final aud = widget.course.audience ?? {};
    final rawScope = aud['scope']?.toString();
    _audienceScope = (rawScope == null || rawScope == 'global')
        ? (workspace.isPrivateWorkspace ? 'tutor_network' : 'institute')
        : rawScope;
    _audienceBatchIds = List<String>.from(aud['batchIds'] ?? []);
    _audienceStudentIds = List<String>.from(aud['studentIds'] ?? []);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      categoryProvider.fetchCategories();
      _loadPayoutStatus();
    });
  }

  Future<void> _loadPayoutStatus() async {
    try {
      final res = await PayoutService.getMyPayoutAccount();
      final status = (res['payoutAccount']?['verificationStatus'] ?? 'not_configured')
          .toString();
      if (mounted) setState(() => _payoutVerificationStatus = status);
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _offlineInstructionsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _updateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    final double numericPrice =
        _isFree ? 0 : (double.tryParse(_priceController.text) ?? 0);
    final String effectivePricingMode = (_isFree || numericPrice <= 0)
        ? 'free'
        : _pricingMode;

    final updates = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'categoryId': _selectedCategoryId,
      'price': numericPrice,
      'isFree': _isFree || numericPrice <= 0,
      'pricingMode': effectivePricingMode,
      'offlinePaymentInstructions': effectivePricingMode == 'offline'
          ? _offlineInstructionsController.text.trim()
          : '',
      'level': _selectedLevel,
      'duration': double.tryParse(_durationController.text) ?? 0,
      'language': _selectedLanguage,
      'audience': {
        'scope': _audienceScope,
        'batchIds': _audienceBatchIds,
        'studentIds': _audienceStudentIds,
      },
    };

    final success = await courseProvider.updateCourse(
      id: widget.course.id,
      updates: updates,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(courseProvider.error ?? 'Failed to update course'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Course'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Course Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter course title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Course Description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter course description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category - ✅ FIXED
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                hint: const Text('Select Category'),
                items: categoryProvider.categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id, // ✅ Use ID as value
                        child: Text('${category.icon} ${category.name}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Level
              DropdownButtonFormField<String>(
                initialValue: _selectedLevel,
                decoration: InputDecoration(
                  labelText: 'Level',
                  prefixIcon: const Icon(Icons.signal_cellular_alt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'beginner',
                    child: Text('🟢 Beginner'),
                  ),
                  DropdownMenuItem(
                    value: 'intermediate',
                    child: Text('🟡 Intermediate'),
                  ),
                  DropdownMenuItem(
                    value: 'advanced',
                    child: Text('🔴 Advanced'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Duration
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'Duration (hours)',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixText: 'hours',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final duration = double.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Please enter a valid duration';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Language
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: 'Language',
                  prefixIcon: const Icon(Icons.language),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('🇬🇧 English')),
                  DropdownMenuItem(value: 'Hindi', child: Text('🇮🇳 Hindi')),
                  DropdownMenuItem(value: 'Hinglish', child: Text('🗣️ Hinglish')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              AudienceSelector(
                initialScope: _audienceScope,
                initialBatchIds: _audienceBatchIds,
                initialStudentIds: _audienceStudentIds,
                courseId: widget.course.id,
                onChanged: (scope, batchIds, studentIds) {
                  setState(() {
                    _audienceScope = scope;
                    _audienceBatchIds = batchIds;
                    _audienceStudentIds = studentIds;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Pricing Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pricing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Free Course'),
                      subtitle: const Text(
                        'Students can enroll without payment',
                      ),
                      value: _isFree,
                      onChanged: (value) {
                        setState(() {
                          _isFree = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!_isFree) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          prefixText: '₹ ',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (!_isFree) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildPricingModeSection(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Update Button
              Consumer<CourseProvider>(
                builder: (context, courseProvider, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: courseProvider.isLoading ? null : _updateCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: courseProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Update Course',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingModeSection() {
    final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
    final bool isPrivateStudio = workspace.isPrivateWorkspace;
    final bool isPayoutVerified = _payoutVerificationStatus == 'verified';
    final bool onlineAllowed = !isPrivateStudio || isPayoutVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Fee Collection Mode',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Offline / Direct Fee'),
              selected: _pricingMode == 'offline',
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: _pricingMode == 'offline' ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => setState(() => _pricingMode = 'offline'),
            ),
            ChoiceChip(
              label: Text(
                onlineAllowed
                    ? 'Online Razorpay'
                    : 'Online Razorpay (KYC Required)',
              ),
              selected: _pricingMode == 'online',
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: _pricingMode == 'online'
                    ? Colors.white
                    : (onlineAllowed ? AppColors.navy : AppColors.textMuted),
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                if (!onlineAllowed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Verify your Bank/UPI payout account in Earnings before switching to online checkout.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => _pricingMode = 'online');
              },
            ),
          ],
        ),
        if (isPrivateStudio && !isPayoutVerified) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorEarningsScreen()),
              ).then((_) => _loadPayoutStatus());
            },
            icon: const Icon(Icons.account_balance_outlined, size: 16),
            label: Text(
              'Payout KYC: $_payoutVerificationStatus — Setup Bank/UPI',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        if (_pricingMode == 'offline') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _offlineInstructionsController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Offline Payment Instructions',
              hintText: 'Bank/UPI or in-class fee instructions',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}