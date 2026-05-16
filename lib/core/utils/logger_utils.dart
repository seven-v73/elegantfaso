import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggerUtils {
  static Logger setupLogger() {
    return Logger(
      level: kDebugMode ? Level.debug : Level.warning,
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: kDebugMode,
        printEmojis: kDebugMode,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }
}
