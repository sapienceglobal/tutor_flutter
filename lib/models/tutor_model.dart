import 'user_model.dart';
import 'category_model.dart';

class TutorModel {
  final String id;
  final UserModel user;
  final CategoryModel category;
  final double hourlyRate;
  final int experience;
  final double rating;
  final int studentsCount;
  final List<String> subjects;
  final String bio;
  final bool isVerified;

  TutorModel({
    required this.id,
    required this.user,
    required this.category,
    required this.hourlyRate,
    required this.experience,
    this.rating = 0.0,
    this.studentsCount = 0,
    this.subjects = const [],
    this.bio = '',
    this.isVerified = false,
  });

  factory TutorModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing TutorModel: ${json['_id']}');

      // ✅ Parse userId (can be object, string, or null) safely
      UserModel user;
      if (json['userId'] != null) {
        if (json['userId'] is Map<String, dynamic>) {
          user = UserModel.fromJson(json['userId']);
        } else {
          user = UserModel(
            id: json['userId'].toString(),
            name: 'Tutor',
            email: '',
            phone: '',
            role: 'tutor',
            profileImage: 'https://via.placeholder.com/150',
            notificationSettings: NotificationSettings(
              email: true,
              push: true,
              sms: false,
            ),
          );
        }
      } else {
        user = UserModel(
          id: '',
          name: 'Tutor',
          email: '',
          phone: '',
          role: 'tutor',
          profileImage: 'https://via.placeholder.com/150',
          notificationSettings: NotificationSettings(
            email: true,
            push: true,
            sms: false,
          ),
        );
      }

      // ✅ Parse categoryId (can be object, string, or null) safely
      CategoryModel category;
      if (json['categoryId'] != null) {
        if (json['categoryId'] is Map<String, dynamic>) {
          category = CategoryModel.fromJson(json['categoryId']);
        } else {
          category = CategoryModel(
            id: json['categoryId'].toString(),
            name: 'Expertise',
            icon: '📚',
          );
        }
      } else {
        category = CategoryModel(id: '', name: 'Expertise', icon: '📚');
      }

      // ✅ Parse subjects safely
      List<String> subjects = [];
      if (json['subjects'] != null && json['subjects'] is List) {
        subjects = (json['subjects'] as List)
            .map((item) => item.toString())
            .toList();
      }

      final tutor = TutorModel(
        id: json['_id']?.toString() ?? '',
        user: user,
        category: category,
        hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
        experience: json['experience'] ?? 0,
        rating: (json['rating'] ?? 0).toDouble(),
        studentsCount: json['studentsCount'] ?? 0,
        subjects: subjects,
        bio: json['bio']?.toString() ?? '',
        isVerified: json['isVerified'] ?? false,
      );

      print('✅ TutorModel parsed successfully');
      return tutor;
    } catch (e) {
      print('❌ Error parsing TutorModel: $e');
      print('JSON Data: $json');
      // Return a safe fallback rather than crashing the whole list
      return TutorModel(
        id: json['_id']?.toString() ?? '',
        user: UserModel(
          id: '',
          name: 'Tutor',
          email: '',
          phone: '',
          role: 'tutor',
          profileImage: 'https://via.placeholder.com/150',
          notificationSettings: NotificationSettings(email: true, push: true, sms: false),
        ),
        category: CategoryModel(id: '', name: 'Expertise', icon: '📚'),
        hourlyRate: 0.0,
        experience: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': user.toJson(),
      'categoryId': category.toJson(),
      'hourlyRate': hourlyRate,
      'experience': experience,
      'rating': rating,
      'studentsCount': studentsCount,
      'subjects': subjects,
      'bio': bio,
      'isVerified': isVerified,
    };
  }
}