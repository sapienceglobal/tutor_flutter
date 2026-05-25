import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/certificate_model.dart';
import '../../../services/certificate_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/constants.dart';

class StudentCertificatesScreen extends StatefulWidget {
  const StudentCertificatesScreen({Key? key}) : super(key: key);

  @override
  State<StudentCertificatesScreen> createState() => _StudentCertificatesScreenState();
}

class _StudentCertificatesScreenState extends State<StudentCertificatesScreen> with SingleTickerProviderStateMixin {
  final _certificateService = CertificateService();
  late TabController _tabController;
  
  List<Certificate> _certificates = [];
  List<InProgressCourse> _inProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final certs = await _certificateService.fetchMyCertificates();
      final inProgress = await _certificateService.fetchInProgressCourses();
      setState(() {
        _certificates = certs;
        _inProgress = inProgress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificates'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Earned (${_certificates.length})'),
            Tab(text: 'In Progress (${_inProgress.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEarnedList(),
                _buildInProgressList(),
              ],
            ),
    );
  }

  Widget _buildEarnedList() {
    if (_certificates.isEmpty) {
      return _buildEmptyState(Icons.emoji_events_outlined, "No certificates yet", "Complete a course to earn your first certificate!");
    }

    return ListView.builder(
      itemCount: _certificates.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final cert = _certificates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(child: Icon(Icons.emoji_events, size: 48, color: Colors.amber)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cert.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${cert.instituteName} • ${DateFormat('MMM d, yyyy').format(cert.issuedAt)}', 
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchURL(cert.downloadUrl),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text("Download"),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _launchURL(cert.verificationUrl),
                          icon: const Icon(Icons.verified_user_outlined, color: Colors.green),
                          tooltip: "Verify",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInProgressList() {
    if (_inProgress.isEmpty) {
      return _buildEmptyState(Icons.menu_book_outlined, "No courses in progress", "Start learning a course to track your progress here.");
    }

    return ListView.builder(
      itemCount: _inProgress.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final course = _inProgress[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: course.progress / 100, backgroundColor: Colors.grey[200], color: AppColors.primary),
                const SizedBox(height: 8),
                Text('${course.progress}% Complete', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(sub, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String? url) async {
    if (url == null) return;
    String finalUrl = url;
    if (url.contains('/certificates/generate/')) {
      final token = await AuthService.getToken();
      if (token != null) {
        finalUrl = '$url?token=$token';
      }
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
