import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_exception.dart';

class SupabaseErrorMapper {
  static AppException parseError(PostgrestException error, String message) {
    if (error.code == 'P0001' &&
        error.message == 'UGC_RULES_ACCEPTANCE_REQUIRED') {
      return AppException(
        code: AppErrorCode.forbidden,
        userMessage: 'UGC_RULES_ACCEPTANCE_REQUIRED',
        technicalMessage: error.message,
        cause: error,
      );
    }
    if (error.code == '22023' && error.message == 'UGC_CONTENT_RESTRICTED') {
      return AppException(
        code: AppErrorCode.validation,
        userMessage:
            'Your content contains restricted words. Please revise it and try again.',
        technicalMessage: error.message,
        cause: error,
      );
    }
    return AppException(
      code: switch (error.code) {
        '23505' => AppErrorCode.conflict,
        '40001' => AppErrorCode.conflict,
        '42501' => AppErrorCode.forbidden,
        _ => AppErrorCode.unexpected,
      },
      userMessage: message,
      technicalMessage: error.message,
      cause: error,
    );
  }
}
