import 'package:logger/logger.dart';

class LoggerUtils {
  static Logger setupLogger() {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }
}