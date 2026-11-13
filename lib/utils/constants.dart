import 'package:flutter/material.dart';

class AppColors {
  // Sapience LMS Official Mobile UI Design System
  static const Color primary = Color(0xFF0B5CFF); // Royal Blue CTA
  static const Color primaryLight = Color(0xFF2079FF);
  static const Color primaryDark = Color(0xFF0650E8);
  static const Color primaryHover = Color(0xFF074AD1);
  static const Color primarySoft = Color(0xFFEAF1FF);

  static const Color navy = Color(0xFF0B1B4D); // Authoritative Heading Ink
  static const Color navyBannerStart = Color(0xFF0B1A45);
  static const Color navyBannerMid = Color(0xFF0E2A6B);
  static const Color navyBannerEnd = Color(0xFF13398A);
  static const Color navBarTop = Color(0xFF0B3FA6);
  static const Color navBarBottom = Color(0xFF0A3491);

  static const Color accent = Color(0xFF16B53A); // Vibrant Emerald Green
  static const Color background = Color(0xFFF4F7FD); // Ice Blue-White Canvas
  static const Color backgroundTop = Color(0xFFF9FBFF);
  static const Color backgroundBottom = Color(0xFFF3F6FD);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF8FAFF);
  static const Color innerSurface = Color(0xFFEEF3FB);
  static const Color cardBorder = Color(0xFFE6EDF8);
  static const Color divider = Color(0xFFE3E9F4);
  static const Color trackBlue = Color(0xFFD3E1F6);

  static const Color success = Color(0xFF16B53A);
  static const Color successDark = Color(0xFF118F2C);
  static const Color successSoft = Color(0xFFE3F7E8);
  static const Color error = Color(0xFFEB1F1F);
  static const Color errorSoft = Color(0xFFFFE8E8);
  static const Color warning = Color(0xFFE68A00);
  static const Color warningSoft = Color(0xFFFFF0D8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFEFE7FD);
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkSoft = Color(0xFFFCE9F1);
  static const Color cyan = Color(0xFF0A9FCF);
  static const Color cyanSoft = Color(0xFFDDF6FB);
  static const Color teal = Color(0xFF00897B);
  static const Color tealSoft = Color(0xFFE0F7F6);

  static const Color textMain = Color(0xFF0B1B4D);
  static const Color textBody = Color(0xFF1C2748);
  static const Color textMuted = Color(0xFF59637E);
  static const Color textSubtle = Color(0xFF8C96B0);

  // Semantic token aliases used across Sapience UI components
  static const Color secondary = accent;
  static const Color navyInk = navy;
  static const Color border = cardBorder;
  static const Color primaryTint = primarySoft;
  static const Color textSecondary = textMuted;

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2079FF), Color(0xFF0650E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient greenGradient = LinearGradient(
    colors: [Color(0xFF1FAE3A), Color(0xFF118F2C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient greenToBlueGradient = LinearGradient(
    colors: [Color(0xFF13C530), Color(0xFF10A85A), Color(0xFF0B5CFF)],
    stops: [0.0, 0.38, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient navyWaveGradient = LinearGradient(
    colors: [Color(0xFF0B1A45), Color(0xFF0E2A6B), Color(0xFF13398A)],
    stops: [0.0, 0.58, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient progressGradient = LinearGradient(
    colors: [Color(0xFF13C530), Color(0xFF10B22D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppThemeDesign {
  // Border Radii Constants
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 22.0;
  static const double radiusExtraLarge = 28.0;

  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusExtraLarge = BorderRadius.circular(radiusExtraLarge);

  static const Gradient greenToBlueGradient = AppColors.greenToBlueGradient;
  static const Gradient navyWaveGradient = AppColors.navyWaveGradient;

  // Padding & Spacing Constants
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Box Shadows (Sapience Mobile Soft Royal-Tint Elevation)
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x161E46A0), // ~9% royal shadow
    blurRadius: 18,
    offset: Offset(0, 6),
  );

  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x141E46A0), // ~8%
    blurRadius: 14,
    offset: Offset(0, 5),
  );

  static const BoxShadow brandShadow = BoxShadow(
    color: Color(0x4D0B5CFF), // 30% Royal Blue glow
    blurRadius: 14,
    offset: Offset(0, 6),
  );

  // Glassmorphic Shadows
  static const BoxShadow glassShadow = BoxShadow(
    color: Color(0x191E46A0),
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  // Clean Card Decoration Builder
  static BoxDecoration buildGlassDecoration({
    Color? color,
    BorderRadius? borderRadius,
    double borderOpacity = 1.0,
  }) {
    return BoxDecoration(
      gradient: color == null
          ? const LinearGradient(
              colors: [Colors.white, Color(0xFFF8FAFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          : null,
      color: color,
      borderRadius: borderRadius ?? borderRadiusMedium,
      border: Border.all(
        color: AppColors.cardBorder,
        width: 1.0,
      ),
      boxShadow: const [cardShadow],
    );
  }

  // Standard Text Styles for LMS parity
  static const TextStyle headingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textMain,
    letterSpacing: -0.3,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: AppColors.textMain,
    height: 1.5,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 📱 PREMIUM TACTILE INTERACTION CONTAINER (Micro-Animations)
// ─────────────────────────────────────────────────────────────────────────────
class InteractivePressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  const InteractivePressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.96,
  });

  @override
  State<InteractivePressScale> createState() => _InteractivePressScaleState();
}

class _InteractivePressScaleState extends State<InteractivePressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class AppStrings {
  static const String appName = 'Sapience LMS';
  static const String learnAtYourPace = 'Empowering Education Everywhere';

  // English
  static const Map<String, String> en = {
    'profile': 'Profile',
    'editProfile': 'Edit Profile',
    'personalInformation': 'Personal Information',
    'email': 'Email',
    'phone': 'Phone',
    'role': 'Role',
    'settings': 'Settings',
    'notifications': 'Notifications',
    'changePassword': 'Change Password',
    'language': 'Language',
    'support': 'Support',
    'helpAndSupport': 'Help & Support',
    'about': 'About',
    'privacyPolicy': 'Privacy Policy',
    'logout': 'Logout',
    'student': 'Student',
    'tutor': 'Tutor',
    'admin': 'Admin',
    'version': 'Version',
    'name': 'Name',
    'save': 'Save',
    'cancel': 'Cancel',
    'currentPassword': 'Current Password',
    'newPassword': 'New Password',
    'confirmPassword': 'Confirm Password',
    'emailNotifications': 'Email Notifications',
    'pushNotifications': 'Push Notifications',
    'smsNotifications': 'SMS Notifications',
    'selectLanguage': 'Select Language',
    'english': 'English',
    'hindi': 'हिंदी',
    'areYouSureLogout': 'Are you sure you want to logout?',
    'yes': 'Yes',
    'no': 'No',
    'profileUpdated': 'Profile updated successfully',
    'passwordChanged': 'Password changed successfully',
    'settingsUpdated': 'Settings updated successfully',
    'somethingWentWrong': 'Something went wrong',
    'enterValidName': 'Please enter a valid name',
    'enterValidPhone': 'Please enter a valid phone number',
    'passwordTooShort': 'Password must be at least 6 characters',
    'passwordsDoNotMatch': 'Passwords do not match',
    'enterCurrentPassword': 'Please enter current password',
    'enterNewPassword': 'Please enter new password',
    'changeProfilePicture': 'Change Profile Picture',
    'takePhoto': 'Take Photo',
    'chooseFromGallery': 'Choose from Gallery',
    'uploadingImage': 'Uploading image...',
    'forgotPassword': 'Forgot Password?',
    'sendOTP': 'Send OTP',
    'verifyOTP': 'Verify OTP',
    'enterOTP': 'Enter OTP',
    'otpSent': 'OTP sent to your email',
    'enterEmail': 'Enter your email',
    'resetPassword': 'Reset Password',
    'backToLogin': 'Back to Login',
  };

  // Hindi
  static const Map<String, String> hi = {
    'profile': 'प्रोफाइल',
    'editProfile': 'प्रोफाइल संपादित करें',
    'personalInformation': 'व्यक्तिगत जानकारी',
    'email': 'ईमेल',
    'phone': 'फोन',
    'role': 'भूमिका',
    'settings': 'सेटिंग्स',
    'notifications': 'सूचनाएं',
    'changePassword': 'पासवर्ड बदलें',
    'language': 'भाषा',
    'support': 'सहायता',
    'helpAndSupport': 'मदद और सहायता',
    'about': 'के बारे में',
    'privacyPolicy': 'गोपनीयता नीति',
    'logout': 'लॉगआउट',
    'student': 'छात्र',
    'tutor': 'शिक्षक',
    'admin': 'व्यवस्थापक',
    'version': 'संस्करण',
    'name': 'नाम',
    'save': 'सेव करें',
    'cancel': 'रद्द करें',
    'currentPassword': 'वर्तमान पासवर्ड',
    'newPassword': 'नया पासवर्ड',
    'confirmPassword': 'पासवर्ड की पुष्टि करें',
    'emailNotifications': 'ईमेल सूचनाएं',
    'pushNotifications': 'पुश सूचनाएं',
    'smsNotifications': 'SMS सूचनाएं',
    'selectLanguage': 'भाषा चुनें',
    'english': 'English',
    'hindi': 'हिंदी',
    'areYouSureLogout': 'क्या आप लॉगआउट करना चाहते हैं?',
    'yes': 'हां',
    'no': 'नहीं',
    'profileUpdated': 'प्रोफाइल सफलतापूर्वक अपडेट हुआ',
    'passwordChanged': 'पासवर्ड सफलतापूर्वक बदला गया',
    'settingsUpdated': 'सेटिंग्स सफलतापूर्वक अपडेट हुईं',
    'somethingWentWrong': 'कुछ गलत हो गया',
    'enterValidName': 'कृपया एक मान्य नाम दर्ज करें',
    'enterValidPhone': 'कृपया एक मान्य फोन नंबर दर्ज करें',
    'passwordTooShort': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
    'passwordsDoNotMatch': 'पासवर्ड मेल नहीं खाते',
    'enterCurrentPassword': 'कृपया वर्तमान पासवर्ड दर्ज करें',
    'enterNewPassword': 'कृपया नया पासवर्ड दर्ज करें',
    'changeProfilePicture': 'प्रोफाइल फोटो बदलें',
    'takePhoto': 'फोटो लें',
    'chooseFromGallery': 'गैलरी से चुनें',
    'uploadingImage': 'छवि अपलोड हो रही है...',
    'forgotPassword': 'पासवर्ड भूल गए?',
    'sendOTP': 'OTP भेजें',
    'verifyOTP': 'OTP सत्यापित करें',
    'enterOTP': 'OTP दर्ज करें',
    'otpSent': 'आपके ईमेल पर OTP भेजा गया',
    'enterEmail': 'अपना ईमेल दर्ज करें',
    'resetPassword': 'पासवर्ड रीसेट करें',
    'backToLogin': 'लॉगिन पर वापस जाएं',
  };
}

// Localization Helper
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  String translate(String key) {
    if (languageCode == 'hi') {
      return AppStrings.hi[key] ?? AppStrings.en[key] ?? key;
    }
    return AppStrings.en[key] ?? key;
  }
}
