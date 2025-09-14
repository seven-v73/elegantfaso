import 'package:flutter/material.dart';

// Modèle de données pour les événements de mode burkinabé
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String imageUrl;
  final String designerName;
  final double price;
  final EventType type;
  final bool isNotificationActive;
  final List<String> tags;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.imageUrl = '',
    this.designerName = '',
    this.price = 0.0,
    this.type = EventType.defileMode,
    this.isNotificationActive = false,
    this.tags = const [],
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? imageUrl,
    String? designerName,
    double? price,
    EventType? type,
    bool? isNotificationActive,
    List<String>? tags,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      designerName: designerName ?? this.designerName,
      price: price ?? this.price,
      type: type ?? this.type,
      isNotificationActive: isNotificationActive ?? this.isNotificationActive,
      tags: tags ?? this.tags,
    );
  }
}

enum EventType {
  defileMode,
  exposition,
  workshop,
  concours,
  lancement,
  ventePrive,
  festival
}

// Extension pour les types d'événements
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.defileMode:
        return 'Défilé de Mode';
      case EventType.exposition:
        return 'Exposition';
      case EventType.workshop:
        return 'Atelier';
      case EventType.concours:
        return 'Concours';
      case EventType.lancement:
        return 'Lancement';
      case EventType.ventePrive:
        return 'Vente Privée';
      case EventType.festival:
        return 'Festival';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.defileMode:
        return Icons.psychology;
      case EventType.exposition:
        return Icons.palette;
      case EventType.workshop:
        return Icons.school;
      case EventType.concours:
        return Icons.emoji_events;
      case EventType.lancement:
        return Icons.rocket_launch;
      case EventType.ventePrive:
        return Icons.shopping_bag;
      case EventType.festival:
        return Icons.festival;
    }
  }

  Color get color {
    switch (this) {
      case EventType.defileMode:
        return const Color(0xFF6B46C1); // Violet
      case EventType.exposition:
        return const Color(0xFFDB2777); // Rose
      case EventType.workshop:
        return const Color(0xFF059669); // Vert
      case EventType.concours:
        return const Color(0xFFDC2626); // Rouge
      case EventType.lancement:
        return const Color(0xFF2563EB); // Bleu
      case EventType.ventePrive:
        return const Color(0xFFD97706); // Orange
      case EventType.festival:
        return const Color(0xFF7C3AED); // Indigo
    }
  }
}

// Service pour gérer les événements de mode burkinabé
class EventService {
  static List<EventModel> _events = [
    EventModel(
      id: '1',
      title: 'Burkina Fashion Week 2025',
      description: 'Le plus grand événement de mode du Burkina Faso avec les créateurs locaux',
      date: DateTime(2025, 7, 15, 19, 0),
      location: 'Palais des Sports, Ouagadougou',
      designerName: 'Collectif BFA Designers',
      price: 15000,
      type: EventType.defileMode,
      tags: ['Faso Dan Fani', 'Mode Africaine', 'Créateurs Locaux'],
      imageUrl: '/api/placeholder/300/200',
    ),
    EventModel(
      id: '2',
      title: 'Atelier Teinture Bogolan',
      description: 'Apprenez les techniques traditionnelles de teinture bogolan',
      date: DateTime(2025, 7, 2, 14, 0),
      location: 'Centre Artisanal, Bobo-Dioulasso',
      designerName: 'Maître Aminata Traoré',
      price: 5000,
      type: EventType.workshop,
      tags: ['Bogolan', 'Artisanat', 'Tradition'],
      isNotificationActive: true,
    ),
    EventModel(
      id: '3',
      title: 'Exposition Faso Dan Fani',
      description: 'Découvrez l\'évolution du tissu traditionnel burkinabé',
      date: DateTime(2025, 6, 30, 10, 0),
      location: 'Musée National, Ouagadougou',
      designerName: 'Association des Tisserands',
      price: 2000,
      type: EventType.exposition,
      tags: ['Faso Dan Fani', 'Histoire', 'Culture'],
    ),
    EventModel(
      id: '4',
      title: 'Concours Jeunes Créateurs',
      description: 'Competition pour révéler les nouveaux talents de la mode burkinabé',
      date: DateTime(2025, 8, 10, 16, 0),
      location: 'Institut Français, Ouagadougou',
      designerName: 'Ministère de la Culture',
      price: 0,
      type: EventType.concours,
      tags: ['Jeunes Talents', 'Innovation', 'Prix'],
    ),
  ];

  static List<EventModel> getUpcomingEvents({int limit = 10}) {
    final now = DateTime.now();
    return _events
        .where((event) => event.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date))
      ..take(limit);
  }

  static void toggleNotification(String eventId) {
    final index = _events.indexWhere((event) => event.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(
        isNotificationActive: !_events[index].isNotificationActive,
      );
    }
  }
}

// Widget principal optimisé pour SingleChildScrollView
class MyEvents extends StatefulWidget {
  final int maxEvents;
  final bool showHeader;
  final VoidCallback? onSeeAll;
  final Function(EventModel)? onEventTap;

  const MyEvents({
    super.key,
    this.maxEvents = 3,
    this.showHeader = true,
    this.onSeeAll,
    this.onEventTap,
  });

  @override
  State<MyEvents> createState() => _MyEventsState();
}

class _MyEventsState extends State<MyEvents> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _loadEvents();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    // Simulation du chargement
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _events = EventService.getUpcomingEvents(limit: widget.maxEvents);
      _isLoading = false;
    });

    _slideController.forward();
  }

  void _toggleNotification(EventModel event) {
    setState(() {
      EventService.toggleNotification(event.id);
      _events = EventService.getUpcomingEvents(limit: widget.maxEvents);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              event.isNotificationActive ? Icons.notifications_off : Icons.notifications_active,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.isNotificationActive
                    ? 'Notification désactivée'
                    : 'Vous serez notifié pour cet événement',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == 0) return 'Gratuit';
    return '${price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]} '
    )} FCFA';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];

    if (difference == 0) {
      return 'Aujourd\'hui ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return 'Demain ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day} ${months[date.month - 1]} • ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) _buildSectionHeader(),
          if (widget.showHeader) const SizedBox(height: 16),
          _isLoading ? _buildLoadingState() : _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Événements Mode',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Découvrez la mode burkinabé',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          if (widget.onSeeAll != null)
            TextButton.icon(
              onPressed: widget.onSeeAll,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B46C1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsList() {
    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _events.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: _buildEventCard(_events[index], index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun événement à venir',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Les prochains événements seront bientôt annoncés !',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, int index) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: index < _events.length - 1 ? 16 : 0),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onEventTap != null
              ? () => widget.onEventTap!(event)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventHeader(event),
              Expanded(child: _buildEventContent(event)),
              _buildEventFooter(event),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventHeader(EventModel event) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            event.type.color,
            event.type.color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            event.type.icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.type.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              event.isNotificationActive
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _toggleNotification(event),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEventContent(EventModel event) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4, // S'adapte à l'écran
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre de l'événement
              Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                event.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Date et heure
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: event.type.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDate(event.date),
                      style: TextStyle(
                        color: event.type.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lieu
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildEventFooter(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonne infos designer + prix
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.designerName.isNotEmpty)
                  Text(
                    event.designerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Color(0xFF374151),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  _formatPrice(event.price),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: event.price == 0
                        ? const Color(0xFF059669)
                        : const Color(0xFF6B46C1),
                  ),
                ),
              ],
            ),
          ),

          // Tags
          if (event.tags.isNotEmpty)
            Flexible(
              flex: 3,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: event.tags.take(2).map((tag) {
                  return Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.type.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: event.type.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

}