import 'package:flutter/material.dart';
import '../../../models/course_model.dart';
import '../../../services/wishlist_service.dart';
import '../../../widgets/course_card.dart';
import '../../courses/course_detail_screen.dart';

class StudentWishlistScreen extends StatefulWidget {
  const StudentWishlistScreen({Key? key}) : super(key: key);

  @override
  State<StudentWishlistScreen> createState() => _StudentWishlistScreenState();
}

class _StudentWishlistScreenState extends State<StudentWishlistScreen> {
  final _wishlistService = WishlistService();
  List<CourseModel> _wishlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _wishlistService.getWishlist();
      setState(() {
        _wishlist = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _removeFromWishlist(String id) async {
    try {
      final success = await _wishlistService.removeFromWishlist(id);
      if (success) {
        setState(() {
          _wishlist.removeWhere((c) => c.id == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishlist.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadWishlist,
                  child: ListView.builder(
                    itemCount: _wishlist.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final course = _wishlist[index];
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)));
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: CourseCard(course: course),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _removeFromWishlist(course.id),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Your wishlist is empty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Save courses you're interested in to see them here.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
