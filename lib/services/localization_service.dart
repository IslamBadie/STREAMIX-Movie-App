import 'package:flutter/material.dart';
import 'package:movies/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal();

  late Locale _currentLocale = const Locale('en');
  late ValueNotifier<Locale> _localeNotifier;

  /// Initialize localization service and load saved locale (if any)
  Future<void> init() async {
    _localeNotifier = ValueNotifier(_currentLocale);
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('app_locale') ?? _currentLocale.languageCode;
      _currentLocale = Locale(lang);
      _localeNotifier.value = _currentLocale;
    } catch (_) {}
  }

  Locale get currentLocale => _currentLocale;

  ValueNotifier<Locale> get localeNotifier => _localeNotifier;

  bool get isArabic => _currentLocale.languageCode == 'ar';

  void setLocale(Locale locale) {
    _currentLocale = locale;
    _localeNotifier.value = locale;

    // Clear app cache when language switches (in background to avoid blocking UI)
    try {
      CacheService().clearAllCache().ignore();
    } catch (_) {}

    // Persist the selected language (fire-and-forget, non-blocking)
    try {
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setString('app_locale', locale.languageCode))
          .ignore();
    } catch (_) {}
  }

  // Translation map: English and Arabic strings
  static const Map<String, Map<String, String>> translations = {
    'appTitle': {'en': 'Movie App', 'ar': 'تطبيق الأفلام'},
    'home': {'en': 'Home', 'ar': 'الرئيسية'},
    'browse': {'en': 'Browse', 'ar': 'استعرض'},
    'search': {'en': 'Search', 'ar': 'بحث'},
    'profile': {'en': 'Profile', 'ar': 'الملف الشخصي'},
    'settings': {'en': 'Settings', 'ar': 'الإعدادات'},
    'chatbot': {'en': 'Chatbot', 'ar': 'روبوت الدردشة'},
    'seeMore': {'en': 'See More', 'ar': 'عرض المزيد'},
    'recommendations': {'en': 'Recommendations', 'ar': 'التوصيات'},
    'genreRecommend': {
      'en': 'Recommend an action movie',
      'ar': 'أوصِ بفيلم أكشن'
    },
    'similarMovie': {
      'en': 'Movies like Inception',
      'ar': 'أفلام مثل Inception'
    },
    'noRecommendations': {
      'en': 'No recommendations available',
      'ar': 'لا توصيات متاحة'
    },
    'login': {'en': 'Login', 'ar': 'دخول'},
    'register': {'en': 'Register', 'ar': 'تسجيل'},
    'logout': {'en': 'Logout', 'ar': 'تسجيل الخروج'},
    'forgotPassword': {'en': 'Forgot Password', 'ar': 'هل نسيت كلمة المرور؟'},
    'email': {'en': 'Email', 'ar': 'البريد الإلكتروني'},
    'password': {'en': 'Password', 'ar': 'كلمة المرور'},
    'confirmPassword': {'en': 'Confirm Password', 'ar': 'تأكيد كلمة المرور'},
    'language': {'en': 'Language', 'ar': 'اللغة'},
    'theme': {'en': 'Theme', 'ar': 'المظهر'},
    'darkMode': {'en': 'Dark Mode', 'ar': 'الوضع الداكن'},
    'lightMode': {'en': 'Light Mode', 'ar': 'الوضع الفاتح'},
    'downloadedMovies': {'en': 'Downloaded Movies', 'ar': 'الأفلام المحملة'},
    'genre': {'en': 'Genre', 'ar': 'النوع'},
    'year': {'en': 'Year', 'ar': 'السنة'},
    'rating': {'en': 'Rating', 'ar': 'التقييم'},
    'description': {'en': 'Description', 'ar': 'الوصف'},
    'cast': {'en': 'Cast', 'ar': 'الممثلون'},
    'directors': {'en': 'Directors', 'ar': 'المخرجون'},
    'watch': {'en': 'Watch', 'ar': 'مشاهدة'},
    'sign_in': {'en': 'Sign In', 'ar': 'تسجيل الدخول'},
    'sign_in_with_google': {
      'en': 'Sign in with Google',
      'ar': 'تسجيل الدخول بواسطة جوجل'
    },
    'or': {'en': 'OR', 'ar': 'أو'},
    'dont_have_account': {
      'en': "Don't have an account?",
      'ar': 'لا تملك حساب؟'
    },
    'have_account': {'en': 'Do you have an account?', 'ar': 'هل لديك حساب؟'},
    'create_account': {'en': 'Create account', 'ar': 'إنشاء حساب'},
    'sign_up': {'en': 'Sign up', 'ar': 'إنشاء حساب'},
    'name': {'en': 'Name', 'ar': 'الاسم'},
    'avatar': {'en': 'Avatar', 'ar': 'الصورة الرمزية'},
    'phone_number': {'en': 'Phone Number', 'ar': 'رقم الهاتف'},
    'please_enter_your_name': {
      'en': 'Please enter your name',
      'ar': 'يرجى إدخال اسمك'
    },
    'please_enter_your_email': {
      'en': 'Please enter your email',
      'ar': 'يرجى إدخال بريدك الإلكتروني'
    },
    'please_enter_password': {
      'en': 'Please enter a password',
      'ar': 'يرجى إدخال كلمة المرور'
    },
    'please_confirm_password': {
      'en': 'Please confirm your password',
      'ar': 'يرجى تأكيد كلمة المرور'
    },
    'invalid_phone': {
      'en': 'Please enter a valid phone number',
      'ar': 'يرجى إدخال رقم هاتف صالح'
    },
    'registration_successful': {
      'en': 'Registration successful! Redirecting to login',
      'ar': 'تم التسجيل بنجاح! جارٍ التحويل إلى صفحة الدخول'
    },
    'email_verification_link_sent': {
      'en': 'Verification link sent to your email. Please check your email.',
      'ar': 'تم إرسال رابط التحقق إلى بريدك الإلكتروني. يرجى فحص بريدك.'
    },
    'please_verify_email_before_login': {
      'en': 'Please verify your email before logging in',
      'ar': 'يرجى التحقق من بريدك الإلكتروني قبل تسجيل الدخول'
    },
    'registration_successful_but_email_issue': {
      'en':
          'Registration successful, but there was an issue sending verification email. Please proceed to login.',
      'ar':
          'تم التسجيل بنجاح، لكن حدثت مشكلة في إرسال البريد الإلكتروني. يرجى المتابعة لتسجيل الدخول.'
    },
    'failed_save_server': {
      'en': 'Failed to save user data to server, continuing locally',
      'ar': 'فشل حفظ بيانات المستخدم على الخادم، سيتم الحفظ محلياً'
    },
    'enter_your_email': {
      'en': 'Enter your email',
      'ar': 'أدخل بريدك الإلكتروني'
    },
    'enter_your_password': {
      'en': 'Enter your password',
      'ar': 'أدخل كلمة المرور'
    },
    'password_min_length': {
      'en': 'Password must be at least 6 characters',
      'ar': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل'
    },
    'google_unavailable': {
      'en': 'Google sign-in is currently unavailable',
      'ar': 'تسجيل الدخول عبر جوجل غير متاح حالياً'
    },
    'add_to_watchlist': {
      'en': 'Add to Watchlist',
      'ar': 'إضافة إلى قائمة المشاهدة'
    },
    'remove_from_watchlist': {
      'en': 'Remove from Watchlist',
      'ar': 'إزالة من قائمة المشاهدة'
    },
    'add_to_favorites': {'en': 'Add to Favorites', 'ar': 'إضافة إلى المفضلة'},
    'remove_from_favorites': {
      'en': 'Remove from Favorites',
      'ar': 'إزالة من المفضلة'
    },
    'favorites': {'en': 'Favorites', 'ar': 'المفضلة'},
    'screenshots': {'en': 'Screenshots', 'ar': 'لقطات شاشة'},
    'similar_movies': {'en': 'Similar Movies', 'ar': 'أفلام مشابهة'},
    'summary': {'en': 'Summary', 'ar': 'الملخص'},
    'available_now': {'en': 'Available Now', 'ar': 'متوفر الآن'},
    'watch_now': {'en': 'Watch Now', 'ar': 'شاهد الآن'},
    'see_more': {'en': 'See More', 'ar': 'عرض المزيد'},
    'edit_profile': {'en': 'Edit Profile', 'ar': 'تعديل الملف'},
    'exit': {'en': 'Exit', 'ar': 'خروج'},
    'watch_list': {'en': 'Watch List', 'ar': 'قائمة المشاهدة'},
    'history': {'en': 'History', 'ar': 'السجل'},
    'search_hint': {'en': 'Search', 'ar': 'ابحث'},
    'movie_recommendation_bot': {
      'en': 'Movie Recommendation Bot 🎥',
      'ar': 'روبوت توصية الأفلام 🎥'
    },
    'type_or_press_mic': {
      'en': 'Type or press the mic...',
      'ar': 'اكتب أو اضغط الميكروفون...'
    },
    'new_conversation': {'en': 'New Conversation', 'ar': 'محادثة جديدة'},
    'close': {'en': 'Close', 'ar': 'إغلاق'},
    'cancel': {'en': 'Cancel', 'ar': 'إلغاء'},
    'yes': {'en': 'Yes', 'ar': 'نعم'},
    'genres': {'en': 'Genres', 'ar': 'الأنواع'},
    'delete_account': {'en': 'Delete Account', 'ar': 'حذف الحساب'},
    'delete_account_confirmation': {
      'en':
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
      'ar':
          'هل أنت متأكد أنك تريد حذف حسابك نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.'
    },
    'account_deleted': {
      'en': 'Account deleted successfully',
      'ar': 'تم حذف الحساب بنجاح'
    },
    'account_delete_error': {
      'en': 'Error deleting account',
      'ar': 'خطأ أثناء حذف الحساب'
    },
    'reenter_password': {
      'en': 'Re-enter Password',
      'ar': 'أعد إدخال كلمة المرور'
    },
    'reauth_failed': {
      'en': 'Re-authentication failed',
      'ar': 'فشل إعادة المصادقة'
    },
    'update_data': {'en': 'Update Data', 'ar': 'تحديث البيانات'},
    'go_to_film': {'en': 'Go to Film', 'ar': 'الذهاب إلى الفيلم'},
    'cache': {'en': 'Cache', 'ar': 'الكاش'},
    'clear_cache': {'en': 'Clear Cache', 'ar': 'مسح الكاش'},
    'clear_cache_confirmation': {
      'en': 'Are you sure you want to clear the app cache?',
      'ar': 'هل أنت متأكد أنك تريد مسح ذاكرة التخزين المؤقت للتطبيق؟'
    },
    'cache_cleared': {'en': 'Cache cleared', 'ar': 'تم مسح الكاش'},
    'clear_history': {'en': 'Clear History', 'ar': 'مسح السجل'},
    'clear_history_confirmation': {
      'en': 'Are you sure you want to clear your watch history?',
      'ar': 'هل أنت متأكد أنك تريد مسح سجل المشاهدة الخاص بك؟'
    },
    'history_cleared': {'en': 'History cleared', 'ar': 'تم مسح السجل'},
    'phone': {'en': 'Phone', 'ar': 'رقم الهاتف'},
    'about_me': {'en': 'About Me', 'ar': 'عني'},
    'date_of_birth': {'en': 'Date of Birth', 'ar': 'تاريخ الميلاد'},
    'gender': {'en': 'Gender', 'ar': 'الجنس'},
    'male': {'en': 'Male', 'ar': 'ذكر'},
    'female': {'en': 'Female', 'ar': 'أنثى'},
    'select_gender': {'en': 'Select Gender', 'ar': 'اختر الجنس'},
    'pick_avatar': {'en': 'Pick Avatar', 'ar': 'اختر صورة'},
    'enter_your_name': {'en': 'Enter your name', 'ar': 'أدخل اسمك'},
    'enter_phone_number': {'en': 'Enter phone number', 'ar': 'أدخل رقم الهاتف'},
    'reset_password': {'en': 'Reset Password', 'ar': 'إعادة تعيين كلمة المرور'},
    'change_password': {'en': 'Change Password', 'ar': 'تغيير كلمة المرور'},
    'change_email': {'en': 'Change Email', 'ar': 'تغيير البريد الإلكتروني'},
    'enter_password': {'en': 'Enter Password', 'ar': 'أدخل كلمة المرور'},
    'enter_new_email': {
      'en': 'Enter New Email',
      'ar': 'أدخل بريداً إلكترونياً جديداً'
    },
    'new_email': {'en': 'New Email', 'ar': 'البريد الإلكتروني الجديد'},
    'email_verification_sent': {
      'en': 'Email verification link sent. Please check your email.',
      'ar': 'تم إرسال رابط التحقق. يرجى فحص بريدك الإلكتروني.'
    },
    'current_password': {'en': 'Current Password', 'ar': 'كلمة المرور الحالية'},
    'new_password': {'en': 'New Password', 'ar': 'كلمة المرور الجديدة'},
    'confirm_password': {'en': 'Confirm Password', 'ar': 'تأكيد كلمة المرور'},
    'change': {'en': 'Change', 'ar': 'تغيير'},
    'enter_current_password': {
      'en': 'Please enter current password',
      'ar': 'يرجى إدخال كلمة المرور الحالية'
    },
    'enter_new_password': {
      'en': 'Please enter new password',
      'ar': 'يرجى إدخال كلمة المرور الجديدة'
    },
    'passwords_not_match': {
      'en': 'Passwords do not match',
      'ar': 'كلمات المرور غير متطابقة'
    },
    'user_not_found': {'en': 'User not found', 'ar': 'المستخدم غير موجود'},
    'incorrect_password': {
      'en': 'Current password is incorrect',
      'ar': 'كلمة المرور الحالية غير صحيحة'
    },
    'password_changed': {
      'en': 'Password changed successfully',
      'ar': 'تم تغيير كلمة المرور بنجاح'
    },
    'error': {'en': 'Error', 'ar': 'خطأ'},
    'error_occurred': {'en': 'An error occurred', 'ar': 'حدث خطأ'},
    'user_disabled': {
      'en': 'This user account has been disabled',
      'ar': 'تم تعطيل هذا الحساب'
    },
    'network_error': {
      'en': 'Network error, check your connection and try again',
      'ar': 'خطأ في الشبكة، تحقق من الاتصال وحاول مرة أخرى'
    },
    'security_verification_issue': {
      'en':
          'Security verification issue, try again later or use a different network',
      'ar': 'مشكلة في التحقق من الأمان، حاول لاحقاً أو استخدم شبكة مختلفة'
    },
    'invalid_email': {
      'en': 'Invalid email address',
      'ar': 'عنوان بريد إلكتروني غير صحيح'
    },
    'too_many_requests': {
      'en': 'Too many attempts, try again later',
      'ar': 'محاولات كثيرة جداً، يرجى المحاولة لاحقاً'
    },
    'email_already_in_use': {
      'en': 'The email is already in use',
      'ar': 'البريد الإلكتروني مستخدم بالفعل'
    },
    'weak_password': {'en': 'Weak password', 'ar': 'كلمة مرور ضعيفة'},
    'movie_deleted_successfully': {
      'en': 'Movie deleted successfully',
      'ar': 'تم حذف الفيلم بنجاح'
    },
    'changes_saved_successfully': {
      'en': 'Changes saved successfully',
      'ar': 'تم حفظ التغييرات بنجاح'
    },
    'password_reset_sent': {
      'en': 'Password reset link has been sent to your email',
      'ar': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'
    },
    'verify_email': {'en': 'Verify Email', 'ar': 'تحقق من البريد الإلكتروني'},
    'forgot_password_description': {
      'en':
          'Enter your email address and we will send you a link to reset your password.',
      'ar':
          'أدخل عنوان بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.'
    },
    'image_not_found': {
      'en': 'Image not found or failed to load',
      'ar': 'لم يتم العثور على الصورة أو فشل تحميلها'
    },
    'results': {'en': 'results', 'ar': 'نتائج'},
    'no_results': {'en': 'No results found', 'ar': 'لم يتم العثور على نتائج'},
    'top_rated': {'en': 'Top Rated', 'ar': 'الأعلى تقييماً'},
    // Genres
    'Action': {'en': 'Action', 'ar': 'أكشن'},
    'Comedy': {'en': 'Comedy', 'ar': 'كوميدي'},
    'Drama': {'en': 'Drama', 'ar': 'دراما'},
    'Horror': {'en': 'Horror', 'ar': 'رعب'},
    'Thriller': {'en': 'Thriller', 'ar': 'إثارة'},
    'Adventure': {'en': 'Adventure', 'ar': 'مغامرة'},
    'Fantasy': {'en': 'Fantasy', 'ar': 'خيال'},
    'Romance': {'en': 'Romance', 'ar': 'رومانسي'},
    'Animation': {'en': 'Animation', 'ar': 'رسوم متحركة'},
    'Sci-Fi': {'en': 'Sci-Fi', 'ar': 'خيال علمي'},
    'Science Fiction': {'en': 'Science Fiction', 'ar': 'خيال علمي'},
    'Crime': {'en': 'Crime', 'ar': 'جريمة'},
    'Documentary': {'en': 'Documentary', 'ar': 'وثائقي'},
    'Family': {'en': 'Family', 'ar': 'عائلي'},
    'Biography': {'en': 'Biography', 'ar': 'سيرة'},
    'History': {'en': 'History', 'ar': 'تاريخ'},
    'Mystery': {'en': 'Mystery', 'ar': 'غموض'},
    'Sport': {'en': 'Sport', 'ar': 'رياضة'},
    'War': {'en': 'War', 'ar': 'حرب'},
    'Western': {'en': 'Western', 'ar': 'غربي'},
    'authentication_success': {
      'en': 'Authentication successful',
      'ar': 'تم التحقق بنجاح'
    },
    'too_many_attempts': {
      'en': 'Too many login attempts. Please try again later.',
      'ar': 'عدد كبير جداً من محاولات الدخول. يرجى المحاولة لاحقاً.'
    },
    'email_not_verified': {
      'en': 'Please verify your email before logging in',
      'ar': 'يرجى التحقق من بريدك الإلكتروني قبل تسجيل الدخول'
    },
    'email_verification_required': {
      'en': 'Email Verification Required',
      'ar': 'التحقق من البريد الإلكتروني مطلوب'
    },
    'please_verify_email_message': {
      'en':
          'Please verify your email address to continue. Check your inbox for the verification link.',
      'ar':
          'يرجى التحقق من عنوان بريدك الإلكتروني للمتابعة. تحقق من صندوق الوارد الخاص بك للحصول على رابط التحقق.'
    },
    'dismiss': {'en': 'Dismiss', 'ar': 'إغلاق'},
    'resend_verification_email': {
      'en': 'Resend Verification Email',
      'ar': 'إعادة إرسال بريد التحقق'
    },
    'verification_email_resent': {
      'en': 'Verification email sent! Check your inbox.',
      'ar': 'تم إرسال بريد التحقق! تحقق من صندوق الوارد الخاص بك.'
    },
    'login_successful': {
      'en': 'Login successful!',
      'ar': 'تم تسجيل الدخول بنجاح!'
    },
    'confirm_delete': {'en': 'Confirm Delete', 'ar': 'تأكيد الحذف'},
    'remove_from': {'en': 'Remove from', 'ar': 'إزالة من'},
    'delete': {'en': 'Delete', 'ar': 'حذف'},
    'removed_successfully': {
      'en': 'removed successfully',
      'ar': 'تم حذفه بنجاح'
    },
    'welcome_chatbot': {
      'en':
          '🎬 Welcome!\nTry: "Show me an action movie" or "A movie like Avatar"',
      'ar': '🎬 أهلاً بك!\nجرب: "أرني فيلم أكشن" أو "فيلم مثل Avatar"'
    },
    'try_action_movie': {
      'en': 'Try: "Show me an action movie"',
      'ar': 'جرب: "أرني فيلم أكشن"'
    },
    'try_similar_movie': {
      'en': 'or "A movie like Avatar"',
      'ar': 'أو "فيلم مثل Avatar"'
    },
  };

  String t(String key) {
    final lang = _currentLocale.languageCode;
    return translations[key]?[lang] ?? translations[key]?['en'] ?? key;
  }

  static void switchLanguage(Locale locale) {
    _instance.setLocale(locale);
  }
}
