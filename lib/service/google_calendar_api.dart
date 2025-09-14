import 'package:googleapis/calendar/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static final _googleSignIn = GoogleSignIn.standard(scopes: [CalendarApi.calendarScope]);

  Future<CalendarApi> _getCalendarApi() async {
    final googleUser = await _googleSignIn.signIn();
    final authHeaders = await googleUser!.authHeaders;
    final authenticatedClient = GoogleAuthClient(authHeaders);
    return CalendarApi(authenticatedClient);
  }

  // Créer un événement dans Google Calendar
  Future<void> createAppointment(String title, DateTime start, DateTime end) async {
    final calendarApi = await _getCalendarApi();
    final event = Event()
      ..summary = title
      ..start = EventDateTime(dateTime: start)
      ..end = EventDateTime(dateTime: end);

    await calendarApi.events.insert(event, 'primary');
  }
}

// Client HTTP personnalisé pour l'authentification
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}