import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

// Service de surveillance automatique des événements mode
class FashionEventService {
  static final FashionEventService _instance = FashionEventService._internal();
  factory FashionEventService() => _instance;
  FashionEventService._internal();

  final StreamController<List<Map<String, dynamic>>> _eventsController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get eventsStream => _eventsController.stream;

  Timer? _autoUpdateTimer;
  List<Map<String, dynamic>> _cachedEvents = [];
  DateTime _lastUpdate = DateTime.now();

  // Sources de données à surveiller automatiquement
  final List<String> _dataSources = [
    'facebook.com/groups/modeBurkinaFaso',
    'instagram.com/hashtag/modeBF',
    'twitter.com/search?q=mode+burkina+faso',
    'ouagafashionweek.com',
    'befreedays.com',
    'journalduburkina.com/mode',
    'lefaso.net/spip.php?rubrique142', // Section Mode
    'burkina24.com/category/mode',
    'fasonews.net/mode-et-beaute',
  ];

  // Mots-clés pour identifier les événements mode
  final List<String> _fashionKeywords = [
    'défilé', 'fashion week', 'collection', 'mode', 'couture', 'styliste',
    'créateur', 'atelier', 'formation', 'exposition', 'lancement',
    'faso dan fani', 'pagne', 'textile', 'design', 'boutique',
    'tendance', 'mannequin', 'podium', 'show', 'vernissage'
  ];

  // Démarrer la surveillance automatique
  void startAutoMonitoring() {
    // Mise à jour toutes les 30 minutes
    _autoUpdateTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _fetchLatestEvents();
    });

    // Première récupération immédiate
    _fetchLatestEvents();
  }

  void stopAutoMonitoring() {
    _autoUpdateTimer?.cancel();
  }

  // Simulation de récupération automatique (à remplacer par vraies API)
  Future<void> _fetchLatestEvents() async {
    try {
      print('🔍 Recherche automatique d\'événements mode...');

      // Simulation d'appels API multiples
      final newEvents = await _simulateMultiSourceFetch();

      // Filtrer et organiser les événements
      final processedEvents = _processAndFilterEvents(newEvents);

      // Détecter les nouveaux événements
      final reallyNewEvents = _detectNewEvents(processedEvents);

      if (reallyNewEvents.isNotEmpty) {
        print('✨ ${reallyNewEvents.length} nouveaux événements détectés !');
        _cachedEvents = processedEvents;
        _lastUpdate = DateTime.now();

        // Notifier les widgets
        _eventsController.add(_cachedEvents);

        // Notifier l'utilisateur des nouveaux événements
        _notifyNewEvents(reallyNewEvents);
      }

    } catch (e) {
      print('❌ Erreur lors de la récupération: $e');
      // Ajouter plus de détails sur l'erreur
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Simulation de récupération multi-sources
  Future<List<Map<String, dynamic>>> _simulateMultiSourceFetch() async {
    final events = <Map<String, dynamic>>[];
    final random = Random();

    // Simuler différentes sources avec délais réalistes
    for (String source in _dataSources.take(3)) {
      await Future.delayed(Duration(milliseconds: 200 + random.nextInt(300)));

      final sourceEvents = await _fetchFromSource(source);
      events.addAll(sourceEvents);
    }

    return events;
  }

  // Simulation de récupération depuis une source spécifique
  Future<List<Map<String, dynamic>>> _fetchFromSource(String source) async {
    final random = Random();

    // Génération d'événements réalistes basés sur la source
    if (source.contains('facebook') || source.contains('instagram')) {
      return _generateSocialMediaEvents();
    } else if (source.contains('ouagafashionweek')) {
      return _generateOfficialEvents();
    } else if (source.contains('journalduburkina') || source.contains('lefaso')) {
      return _generateNewsEvents();
    }

    return [];
  }

  List<Map<String, dynamic>> _generateSocialMediaEvents() {
    final random = Random();
    final socialEvents = [
      {
        'title': 'Flash Sale - Collection Automne',
        'creator': 'Boutique Élégance BF',
        'type': 'Promotion',
        'source': 'Facebook',
        'urgency': 'high',
        // CORRECTION: Convertir DateTime en String ISO
        'validUntil': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
      },
      {
        'title': 'Nouveau Partenariat Créateurs',
        'creator': 'Collectif Mode BF',
        'type': 'Annonce',
        'source': 'Instagram',
        'urgency': 'medium',
      },
    ];

    return socialEvents.where((e) => random.nextBool()).toList();
  }

  List<Map<String, dynamic>> _generateOfficialEvents() {
    return [
      {
        'title': 'Ouaga Fashion Week - Appel à Candidatures',
        'creator': 'Ouaga Fashion Week',
        'type': 'Casting',
        'source': 'Site Officiel',
        'urgency': 'high',
        // CORRECTION: Convertir DateTime en String ISO
        'deadline': DateTime.now().add(Duration(days: 15)).toIso8601String(),
      },
    ];
  }

  List<Map<String, dynamic>> _generateNewsEvents() {
    return [
      {
        'title': 'Nouveau Centre de Formation Mode',
        'creator': 'École Supérieure de Mode BF',
        'type': 'Actualité',
        'source': 'Presse',
        'urgency': 'medium',
      },
    ];
  }

  // Traitement et filtrage intelligent des événements
  List<Map<String, dynamic>> _processAndFilterEvents(List<Map<String, dynamic>> rawEvents) {
    final now = DateTime.now();

    return rawEvents.map((event) {
      // Créer une copie de l'événement pour éviter les modifications directes
      final processedEvent = Map<String, dynamic>.from(event);

      // Enrichir avec des données calculées
      processedEvent['id'] = _generateEventId(event);
      processedEvent['discoveredAt'] = now.toIso8601String(); // CORRECTION: String ISO
      processedEvent['relevanceScore'] = _calculateRelevanceScore(event);
      processedEvent['category'] = _categorizeEvent(event);
      processedEvent['location'] = _inferLocation(event);
      processedEvent['estimatedDate'] = _estimateEventDate(event);

      return processedEvent;
    }).where((event) {
      // Filtrer les événements pertinents
      return (event['relevanceScore'] as double) > 0.6 &&
          _isRelevantForBurkinaFaso(event);
    }).toList()
      ..sort((a, b) => (b['relevanceScore'] as double).compareTo(a['relevanceScore'] as double));
  }

  String _generateEventId(Map<String, dynamic> event) {
    final content = '${event['title']}_${event['creator']}_${event['source']}';
    return content.hashCode.abs().toString();
  }

  double _calculateRelevanceScore(Map<String, dynamic> event) {
    double score = 0.5; // Score de base

    final title = (event['title'] as String? ?? '').toLowerCase();
    final creator = (event['creator'] as String? ?? '').toLowerCase();

    // Bonus pour mots-clés mode
    for (String keyword in _fashionKeywords) {
      if (title.contains(keyword) || creator.contains(keyword)) {
        score += 0.1;
      }
    }

    // Bonus selon le type d'événement
    switch (event['type']) {
      case 'Fashion Week':
      case 'Défilé':
        score += 0.3;
        break;
      case 'Formation':
      case 'Atelier':
        score += 0.2;
        break;
      case 'Promotion':
        score += 0.15;
        break;
    }

    // Bonus pour urgence
    if (event['urgency'] == 'high') score += 0.2;
    if (event['urgency'] == 'medium') score += 0.1;

    return math.min(1.0, score);
  }

  String _categorizeEvent(Map<String, dynamic> event) {
    final title = (event['title'] as String? ?? '').toLowerCase();

    if (title.contains('fashion week') || title.contains('défilé')) return 'Fashion Week';
    if (title.contains('formation') || title.contains('atelier')) return 'Formation';
    if (title.contains('exposition') || title.contains('vernissage')) return 'Exposition';
    if (title.contains('promotion') || title.contains('sale')) return 'Promotion';
    if (title.contains('casting') || title.contains('candidature')) return 'Casting';

    return event['type'] ?? 'Événement';
  }

  String _inferLocation(Map<String, dynamic> event) {
    final content = '${event['title'] ?? ''} ${event['creator'] ?? ''}'.toLowerCase();

    if (content.contains('ouaga')) return 'Ouagadougou';
    if (content.contains('bobo')) return 'Bobo-Dioulasso';
    if (content.contains('koudougou')) return 'Koudougou';
    if (content.contains('centre-ouest')) return 'Région Centre-Ouest';

    return 'Burkina Faso'; // Par défaut
  }

  String _estimateEventDate(Map<String, dynamic> event) {
    // CORRECTION: Vérifier d'abord si les clés existent et traiter les différents types
    if (event.containsKey('validUntil')) {
      final validUntil = event['validUntil'];
      if (validUntil is DateTime) {
        return validUntil.toIso8601String();
      } else if (validUntil is String) {
        return validUntil;
      }
    }

    if (event.containsKey('deadline')) {
      final deadline = event['deadline'];
      if (deadline is DateTime) {
        return deadline.toIso8601String();
      } else if (deadline is String) {
        return deadline;
      }
    }

    // Estimation basée sur le type
    final now = DateTime.now();
    switch (event['type']) {
      case 'Promotion':
        return now.add(Duration(days: Random().nextInt(7) + 1)).toIso8601String();
      case 'Casting':
        return now.add(Duration(days: Random().nextInt(30) + 7)).toIso8601String();
      case 'Fashion Week':
        return now.add(Duration(days: Random().nextInt(90) + 30)).toIso8601String();
      default:
        return now.add(Duration(days: Random().nextInt(60) + 14)).toIso8601String();
    }
  }

  bool _isRelevantForBurkinaFaso(Map<String, dynamic> event) {
    final content = '${event['title'] ?? ''} ${event['creator'] ?? ''}'.toLowerCase();
    final source = (event['source'] as String? ?? '').toLowerCase();
    final location = (event['location'] as String? ?? '').toLowerCase();

    return content.contains('burkina') ||
        content.contains('ouaga') ||
        content.contains('bobo') ||
        content.contains('faso') ||
        source.contains('burkina') ||
        location.contains('burkina');
  }

  // Détecter les vraiment nouveaux événements
  List<Map<String, dynamic>> _detectNewEvents(List<Map<String, dynamic>> events) {
    final existingIds = _cachedEvents.map((e) => e['id']).toSet();
    return events.where((event) => !existingIds.contains(event['id'])).toList();
  }

  // Notification des nouveaux événements
  void _notifyNewEvents(List<Map<String, dynamic>> newEvents) {
    // Ici vous pourriez envoyer des notifications push
    for (var event in newEvents) {
      print('🔔 Nouvel événement: ${event['title']} par ${event['creator']}');
    }
  }

  // API publique pour récupération manuelle
  Future<List<Map<String, dynamic>>> getLatestEvents() async {
    if (_cachedEvents.isEmpty ||
        DateTime.now().difference(_lastUpdate).inMinutes > 5) {
      await _fetchLatestEvents();
    }
    return _cachedEvents;
  }

  void dispose() {
    _autoUpdateTimer?.cancel();
    _eventsController.close();
  }
}

// Widget principal avec surveillance automatique
class UpcomingEvents extends StatefulWidget {
  const UpcomingEvents({super.key});

  @override
  State<UpcomingEvents> createState() => _UpcomingEventsState();
}

class _UpcomingEventsState extends State<UpcomingEvents> {
  final FashionEventService _eventService = FashionEventService();
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;
  StreamSubscription? _eventsSubscription;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _initializeAutoSystem();
  }

  void _initializeAutoSystem() {
    // Démarrer la surveillance automatique
    _eventService.startAutoMonitoring();

    // S'abonner au flux d'événements
    _eventsSubscription = _eventService.eventsStream.listen((newEvents) {
      if (mounted) {
        setState(() {
          events = _mergeWithStaticEvents(newEvents);
          isLoading = false;
          _lastUpdateTime = DateTime.now();
        });

        // Afficher notification de mise à jour
        _showUpdateNotification(newEvents.length);
      }
    });

    // Chargement initial
    _loadInitialEvents();
  }

  Future<void> _loadInitialEvents() async {
    final initialEvents = await _eventService.getLatestEvents();

    if (mounted) {
      setState(() {
        events = _mergeWithStaticEvents(initialEvents);
        isLoading = false;
        _lastUpdateTime = DateTime.now();
      });
    }
  }

  // Fusionner avec des événements statiques de base
  List<Map<String, dynamic>> _mergeWithStaticEvents(List<Map<String, dynamic>> dynamicEvents) {
    final staticEvents = _getStaticBaseEvents();
    final allEvents = [...dynamicEvents, ...staticEvents];

    // Déduplication par ID
    final Map<String, Map<String, dynamic>> uniqueEvents = {};
    for (var event in allEvents) {
      uniqueEvents[event['id']] = event;
    }

    return uniqueEvents.values.toList()
      ..sort((a, b) {
        final aScore = a['relevanceScore'] as double? ?? 0.5;
        final bScore = b['relevanceScore'] as double? ?? 0.5;
        return bScore.compareTo(aScore);
      });
  }

  List<Map<String, dynamic>> _getStaticBaseEvents() {
    final now = DateTime.now();
    return [
      {
        'id': 'static_1',
        'title': 'BeFree Fashion Days 2025',
        'creator': 'Lamiz BeFree',
        'type': 'Fashion Week',
        'location': 'Ouagadougou',
        'estimatedDate': now.add(Duration(days: 7)).toIso8601String(), // CORRECTION
        'relevanceScore': 0.9,
        'source': 'Base',
        'isRegistered': false,
      },
      {
        'id': 'static_2',
        'title': 'Atelier Faso Dan Fani',
        'creator': 'Créateurs Unis BF',
        'type': 'Formation',
        'location': 'Koudougou',
        'estimatedDate': now.add(Duration(days: 14)).toIso8601String(), // CORRECTION
        'relevanceScore': 0.8,
        'source': 'Base',
        'isRegistered': false,
      },
    ];
  }

  void _showUpdateNotification(int newEventsCount) {
    if (newEventsCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🆕 $newEventsCount nouveaux événements détectés !'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              // Scroll vers le haut pour voir les nouveaux événements
            },
          ),
        ),
      );
    }
  }

  Future<void> _manualRefresh() async {
    setState(() => isLoading = true);
    await _eventService._fetchLatestEvents();
  }

  String _formatLastUpdate() {
    if (_lastUpdateTime == null) return '';

    final diff = DateTime.now().difference(_lastUpdateTime!);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  // Helper method pour parser les dates string en DateTime de manière sécurisée
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is DateTime) return dateValue;

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('Erreur parsing date: $dateValue');
        return null;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut de mise à jour automatique
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Événements Mode BF',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Mise à jour auto • ${_formatLastUpdate()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Indicateur de nouvelles données
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isLoading ? Colors.orange : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  // Bouton de rafraîchissement manuel
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20),
                    onPressed: _manualRefresh,
                    tooltip: 'Actualiser maintenant',
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 12),

          if (isLoading && events.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Recherche d\'événements...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventCard(event);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    // CORRECTION: Parsing sécurisé de la date de découverte
    final discoveredAt = _parseDate(event['discoveredAt']);
    final isNew = discoveredAt != null &&
        DateTime.now().difference(discoveredAt).inHours < 2;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isNew ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNew ? BorderSide(color: Colors.green, width: 1) : BorderSide.none,
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Badge nouveau
                    if (isNew)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'NOUVEAU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Spacer(),
                    // Source de l'information
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event['source'] ?? 'Auto',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Text(
                  event['title'] ?? 'Événement Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                Text(
                  event['creator'] ?? 'Créateur',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),

                SizedBox(height: 4),

                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                    Text(
                      ' ${event['location'] ?? 'Burkina Faso'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.category, size: 12, color: Colors.grey[600]),
                    Text(
                      ' ${event['category'] ?? event['type'] ?? 'Événement'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Indicateur de pertinence
          if (event['relevanceScore'] != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: _getRelevanceColor(event['relevanceScore'] as double? ?? 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRelevanceColor(double score) {
    if (score > 0.8) return Colors.green;
    if (score > 0.6) return Colors.orange;
    return Colors.grey;
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _eventService.stopAutoMonitoring();
    super.dispose();
  }
}