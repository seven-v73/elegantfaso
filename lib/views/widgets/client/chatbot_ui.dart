import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatbotUI extends StatefulWidget {
  final String conversationId;
  final Function(bool)? onChatbotToggled;

  const ChatbotUI({
    Key? key,
    required this.conversationId,
    this.onChatbotToggled,
  }) : super(key: key);

  @override
  State<ChatbotUI> createState() => _ChatbotUIState();
}

class _ChatbotUIState extends State<ChatbotUI> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isConnected = true;
  List<ChatMessage> _messages = [];
  late AnimationController _animationController;
  bool _showQuickOptions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkConnection();
    _loadHistory();
  }

  Future<void> _checkConnection() async {
    try {
      final isHealthy = await ChatbotService.checkHealth();
      setState(() => _isConnected = isHealthy);

      if (!isHealthy) {
        _messages.add(ChatMessage(
          text: "Le services chatbot est temporairement indisponible. Veuillez réessayer plus tard.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _messages.add(ChatMessage(
          text: "Erreur de connexion au services chatbot.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ChatbotService.getHistory(widget.conversationId);
      if (history.isNotEmpty) {
        setState(() {
          _messages = history.map((e) => ChatMessage(
            text: e['text'],
            isUser: e['isUser'],
            timestamp: DateTime.parse(e['timestamp']),
            intent: e['intent'],
            metadata: e['metadata'],
            type: MessageType.values.firstWhere(
                  (type) => type.toString() == e['type'],
              orElse: () => MessageType.text,
            ),
          )).toList();
        });
        _scrollToBottom();
      } else {
        _sendWelcomeMessage();
      }
    } catch (e) {
      _sendWelcomeMessage();
    }
  }

  void _sendWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "Bonjour! Je suis votre assistant styliste. Comment puis-je vous aider aujourd'hui?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contextProvider = Provider.of<ContextProvider>(context);

    return Column(
      children: [
        _buildHeader(context),
        Expanded(child: _buildMessagesList()),
        if (!_isConnected) _buildConnectionWarning(),
        _buildInputArea(contextProvider, theme),
        if (_showQuickOptions) _buildExpandedQuickOptions(theme),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: SvgPicture.asset(
              'assets/images/fashion-bot.svg',
              width: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Stylist Assistant',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showBotInfo,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showContextSettings,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => widget.onChatbotToggled?.call(false),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.03),
            Theme.of(context).colorScheme.primary.withOpacity(0.01),
          ],
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        itemCount: _messages.length + (_isTyping ? 1 : 0),
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          if (_isTyping && index == 0) {
            return _buildTypingIndicator();
          }
          final message = _messages[_messages.length - 1 - (index - (_isTyping ? 1 : 0))];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.white),
            ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: message.isUser
                      ? const Radius.circular(12)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.outfitSuggestion)
                    _buildOutfitSuggestion(message),
                  if (message.type == MessageType.text)
                    Text(
                      message.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: message.isUser
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                  if (message.metadata?['accessories'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Accessoires: ${message.metadata!['accessories']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (message.metadata?['image_url'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message.metadata!['image_url'],
                          placeholder: (context, url) => const ListTileShimmer(),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.error_outline),
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        message.formattedTime,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser)
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.secondary,
              child: const Icon(Icons.person, size: 14, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildOutfitSuggestion(ChatMessage message) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (message.metadata?['occasion'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(message.metadata!['occasion']),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (message.metadata?['season'] != null)
                  Chip(
                    label: Text(message.metadata!['season']),
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.white),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: const SizedBox(
              height: 30,
              width: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DotAnimation(delay: 0),
                  DotAnimation(delay: 0.2),
                  DotAnimation(delay: 0.4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.orange.withOpacity(0.3)),
          bottom: BorderSide(color: Colors.orange.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.withOpacity(0.8), size: 16),
          const SizedBox(width: 8),
          Text(
            'Connexion limitée - Mode hors ligne',
            style: TextStyle(
              color: Colors.orange.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ContextProvider contextProvider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: _showQuickOptions ? 0 : 40,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add,
                        color: theme.colorScheme.primary),
                    onPressed: () {
                      setState(() {
                        _showQuickOptions = !_showQuickOptions;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.background,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.mic,
                              color: theme.colorScheme.primary),
                          onPressed: _startVoiceInput,
                        ),
                      ),
                      onSubmitted: _handleSubmitted,
                      enabled: _isConnected,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.send,
                        color: theme.colorScheme.onPrimary),
                    onPressed: () => _handleSubmitted(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedQuickOptions(ThemeData theme) {
    final quickOptions = [
      {'text': 'Tenue professionnelle', 'icon': Icons.work_outline},
      {'text': 'Tenue décontractée', 'icon': Icons.weekend_outlined},
      {'text': 'Tenue de soirée', 'icon': Icons.nightlife_outlined},
      {'text': 'Tenue de mariage', 'icon': Icons.celebration_outlined},
      {'text': 'Accessoires', 'icon': Icons.watch_outlined},
      {'text': 'Chaussures', 'icon': Icons.shopping_bag_outlined},
      {'text': 'Conseils mode', 'icon': Icons.lightbulb_outline},
      {'text': 'Dernières tendances', 'icon': Icons.trending_up_outlined},
    ];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Options rapides',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _showQuickOptions = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: quickOptions.length,
              itemBuilder: (context, index) {
                final option = quickOptions[index];
                return _buildQuickOptionItem(
                  option['text'] as String,
                  option['icon'] as IconData,
                  theme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOptionItem(String text, IconData icon, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showQuickOptions = false;
        });
        _handleSubmitted(text);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || !_isConnected) return;

    _textController.clear();
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final contextProvider = Provider.of<ContextProvider>(context, listen: false);
      final response = await ChatbotService.sendMessage(
        text: text,
        conversationId: widget.conversationId,
        gender: contextProvider.gender,
        budget: contextProvider.budget,
        temperature: contextProvider.weather,
        culture: contextProvider.culture,
      );

      setState(() {
        _messages.add(ChatMessage.fromApiResponse(response));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "Désolé, je n'ai pas pu traiter votre demande. Veuillez réessayer.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startVoiceInput() {
    // TODO: Implement voice input functionality
  }

  void _showContextSettings() {
    final contextProvider = Provider.of<ContextProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Paramètres du contexte',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsDropdown(
                      context: context,
                      value: contextProvider.gender,
                      items: ['Homme', 'Femme', 'Unisexe'],
                      label: 'Genre',
                      icon: Icons.person_outline,
                      onChanged: (value) {
                        setState(() {
                          contextProvider.gender = value ?? 'Unisexe';
                        });
                      },
                    ),
                    _buildSettingsDropdown(
                      context: context,
                      value: contextProvider.budget,
                      items: ['Économique', 'Moyen', 'Haut de gamme'],
                      label: 'Budget',
                      icon: Icons.attach_money_outlined,
                      onChanged: (value) {
                        setState(() {
                          contextProvider.budget = value ?? 'Moyen';
                        });
                      },
                    ),
                    _buildSettingsDropdown(
                      context: context,
                      value: contextProvider.weather,
                      items: ['Chaud', 'Tempéré', 'Froid'],
                      label: 'Météo',
                      icon: Icons.wb_sunny_outlined,
                      onChanged: (value) {
                        setState(() {
                          contextProvider.weather = value ?? 'Tempéré';
                        });
                      },
                    ),
                    _buildSettingsDropdown(
                      context: context,
                      value: contextProvider.culture,
                      items: ['Mooré', 'Dioula', 'Peulh', 'Autre'],
                      label: 'Culture',
                      icon: Icons.public_outlined,
                      onChanged: (value) {
                        setState(() {
                          contextProvider.culture = value ?? 'Autre';
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Enregistrer les paramètres'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        dropdownColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  void _showBotInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('À propos du chatbot'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stylist Assistant',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Version 1.2.0',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16),
              Text(
                'Cet assistant vous aide à trouver des tenues adaptées à vos besoins, en tenant compte de vos préférences et du contexte.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class DotAnimation extends StatefulWidget {
  final double delay;

  const DotAnimation({Key? key, required this.delay}) : super(key: key);

  @override
  State<DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<DotAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.delay,
          1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? intent;
  final Map<String, dynamic>? metadata;
  final MessageType type;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.intent,
    this.metadata,
    this.type = MessageType.text,
  });

  String get formattedTime => DateFormat.Hm().format(timestamp);

  factory ChatMessage.fromApiResponse(Map<String, dynamic> response) {
    return ChatMessage(
      text: response['text'],
      isUser: false,
      timestamp: DateTime.now(),
      intent: response['intent'],
      metadata: response['metadata'],
      type: MessageType.values.firstWhere(
            (type) => type.toString() == response['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
}

enum MessageType {
  text,
  outfitSuggestion,
}

class ChatbotService {
  static Future<bool> checkHealth() async {
    // TODO: Implement actual health check
    return true;
  }

  static Future<List<Map<String, dynamic>>> getHistory(String conversationId) async {
    // TODO: Implement actual history retrieval
    return [];
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String text,
    required String conversationId,
    required String gender,
    required String budget,
    required String temperature,
    required String culture,
  }) async {
    // TODO: Implement actual message sending
    return {
      'text': 'Réponse du chatbot',
      'isUser': false,
      'timestamp': DateTime.now().toString(),
      'type': MessageType.text.toString(),
    };
  }
}

class ContextProvider extends ChangeNotifier {
  String _gender = 'Unisexe';
  String _budget = 'Moyen';
  String _weather = 'Tempéré';
  String _culture = 'Autre';

  String get gender => _gender;
  String get budget => _budget;
  String get weather => _weather;
  String get culture => _culture;

  set gender(String value) {
    _gender = value;
    notifyListeners();
  }

  set budget(String value) {
    _budget = value;
    notifyListeners();
  }

  set weather(String value) {
    _weather = value;
    notifyListeners();
  }

  set culture(String value) {
    _culture = value;
    notifyListeners();
  }
}