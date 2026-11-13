import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../models/tutor_model.dart';
import '../screens/tutors/tutor_detail_screen.dart';
import '../utils/constants.dart';
import 'sapience_ui.dart';

class TutorCard extends StatelessWidget {
  final TutorModel tutor;

  const TutorCard({super.key, required this.tutor});

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = ApiConfig.resolveMediaUrl(tutor.user.profileImage);

    return SapienceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TutorDetailScreen(tutor: tutor),
          ),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: resolvedAvatar,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 62,
                height: 62,
                color: AppColors.primaryTint,
                child: const Icon(Icons.person_rounded, size: 30, color: AppColors.primary),
              ),
              errorWidget: (context, url, error) => Container(
                width: 62,
                height: 62,
                color: AppColors.primaryTint,
                child: const Icon(Icons.person_rounded, size: 30, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tutor.user.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tutor.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 17,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tutor.category.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 15, color: AppColors.warning),
                    const SizedBox(width: 3),
                    Text(
                      '${tutor.rating.toStringAsFixed(1)} (${tutor.studentsCount})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${tutor.experience} yrs exp',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${tutor.hourlyRate.toStringAsFixed(0)}/hr',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
