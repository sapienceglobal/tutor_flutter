import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/review_service.dart';
import '../../../utils/constants.dart';

class TutorReviewsScreen extends StatefulWidget {
  const TutorReviewsScreen({super.key});

  @override
  State<TutorReviewsScreen> createState() => _TutorReviewsScreenState();
}

class _TutorReviewsScreenState extends State<TutorReviewsScreen> {
  List<dynamic> _reviews = [];
  bool _loading = true;
  String? _replyingToId;
  final TextEditingController _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => _loading = true);
    try {
      final res = await ReviewService.getTutorReviews(token: token);
      setState(() => _reviews = res['reviews'] ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reviews: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReply(String reviewId) async {
    final reply = _replyCtrl.text.trim();
    if (reply.isEmpty) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final res = await ReviewService.replyToReview(
        token: token,
        reviewId: reviewId,
        reply: reply,
      );
      if (res['success'] == true) {
        setState(() {
          _replyingToId = null;
          _replyCtrl.clear();
        });
        _fetchReviews();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reply posted successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post reply: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _reviews.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchReviews,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _buildReviewCard(_reviews[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_outline_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No Reviews Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 8),
          Text('Reviews from your students will appear here.', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final student = review['studentId'] ?? {};
    final studentName = student['name'] ?? 'Student';
    final course = review['courseId'] ?? {};
    final courseTitle = course['title'] ?? '';
    final rating = review['rating'] ?? 5;
    final comment = review['comment'] ?? '';
    final createdAt = review['createdAt'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(review['createdAt']))
        : '';
    final tutorResponse = review['tutorResponse'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 16,
                            color: index < rating ? AppColors.warning : Colors.grey[300],
                          ),
                        ),
                        if (courseTitle.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              courseTitle,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                createdAt,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"$comment"',
              style: const TextStyle(fontSize: 13, height: 1.4, fontStyle: FontStyle.italic, color: AppColors.textMain),
            ),
          ),
          const SizedBox(height: 12),
          if (tutorResponse != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      const Text(
                        'Your Reply',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      if (tutorResponse['respondedAt'] != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· ${DateFormat('dd MMM yyyy').format(DateTime.parse(tutorResponse['respondedAt']))}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tutorResponse['comment'] ?? '',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ] else if (_replyingToId == review['_id']) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _replyCtrl,
                  decoration: InputDecoration(
                    hintText: 'Type your reply to the student...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _replyingToId = null;
                          _replyCtrl.clear();
                        });
                      },
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () => _submitReply(review['_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _replyingToId = review['_id'];
                  _replyCtrl.clear();
                });
              },
              icon: const Icon(Icons.reply_rounded, size: 14),
              label: const Text('Reply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
