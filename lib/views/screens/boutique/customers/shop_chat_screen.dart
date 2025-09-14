import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'user_model.dart';
import 'package:elegantfaso/views/screens/client/marketplace/chat_service.dart';

class ShopChatScreen extends StatefulWidget {
  final UserModel currentUser;
  final String receiverId;
  final String receiverName;
  final String? receiverImage;

  const ShopChatScreen({
    super.key,
    required this.currentUser,
    required this.receiverId,
    required this.receiverName,
    this.receiverImage,
  });

  @override
  State<ShopChatScreen> createState() => _ShopChatScreenState();
}

class _ShopChatScreenState extends State<ShopChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AutoScrollController _scrollController = AutoScrollController();
  final FocusNode _focusNode = FocusNode();
  final _messageFormKey = GlobalKey<FormState>();
  bool _isTyping = false;
  Timer? _typingTimer;
  late String _conversationId;
  bool _isSending = false;
  bool _showScrollToBottom = false;
  final double _scrollThreshold = 100.0;
  final Map<String, int> _messageIndexMap = {};
  bool _isScrollingManually = false;
  Timer? _scrollCheckTimer;
  bool _isDateFormatInitialized = false;

  @override
  void initState() {
    super.initState();
    _conversationId = _chatService.generateConversationId(
      widget.currentUser.id,
      widget.receiverId,
    );
    _initDateFormatting();
    _initChat();
    _chatService.updateUserPresence(isOnline: true);
    _scrollController.addListener(_handleScroll);
  }

  Future<void> _initDateFormatting() async {
    await initializeDateFormatting('fr_FR', null);
    setState(() => _isDateFormatInitialized = true);
  }

  @override
  void dispose() {
    _chatService.updateUserPresence(isOnline: false);
    _chatService.clearTypingIndicator(_conversationId);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _scrollCheckTimer?.cancel();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 50;
    final shouldShowButton = position.pixels < position.maxScrollExtent - _scrollThreshold;

    setState(() {
      _showScrollToBottom = shouldShowButton;
      _isScrollingManually = !isAtBottom;
    });
  }

  void _initChat() async {
    try {
      await _chatService.ensureConversationExists(
          _conversationId,
          [widget.currentUser.id, widget.receiverId]
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollToBottom(animated: false);
        _chatService.markMessagesAsRead(_conversationId);
      });

      _focusNode.addListener(() {
        if (_focusNode.hasFocus && !_isScrollingManually) {
          _scrollToBottom();
        }
      });

      _scrollCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!_scrollController.hasClients || _isScrollingManually) return;
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint("Erreur d'initialisation du chat: $e");
    }
  }

  Future<void> _scrollToBottom({bool animated = true}) async {
    // Vérifie que le ScrollController est attaché et qu'il y a au moins un message
    if (!_scrollController.hasClients || _messageIndexMap.isEmpty) return;

    // Détermine l'index du dernier message
    final lastIndex = _messageIndexMap.length - 1;

    try {
      // Scroll vers le dernier message avec ou sans animation
      await _scrollController.scrollToIndex(
        lastIndex,
        duration: animated ? const Duration(milliseconds: 300) : Duration.zero,
        preferPosition: AutoScrollPosition.end,
      );

      // (Optionnel) met en évidence l'élément scrollé
      _scrollController.highlight(lastIndex);
    } catch (e) {
      // Capture et affiche les erreurs pour le debug
      debugPrint('Erreur lors du scroll vers le bas : $e');
    }

    // Mise à jour de l'interface utilisateur
    if (mounted) {
      setState(() {
        _showScrollToBottom = false;
      });
    }
  }


  void _onTypingChanged(String text) {
    if (!mounted) return;

    if (text.isNotEmpty) {
      if (!_isTyping) {
        _chatService.sendTypingIndicator(_conversationId);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _chatService.clearTypingIndicator(_conversationId);
          setState(() => _isTyping = false);
        }
      });
      setState(() => _isTyping = true);
    } else if (_isTyping) {
      _chatService.clearTypingIndicator(_conversationId);
      setState(() => _isTyping = false);
    }
  }

  Future<void> _sendMessage() async {
    if (!_messageFormKey.currentState!.validate()) return;

    final message = _messageController.text.trim();
    if (_isSending || message.isEmpty) return;

    setState(() => _isSending = true);
    _chatService.clearTypingIndicator(_conversationId);

    try {
      await _chatService.sendMessage(
        conversationId: _conversationId,
        receiverId: widget.receiverId,
        message: message,
        senderName: widget.currentUser.displayName,
        senderImage: widget.currentUser.photoUrl,
      );
      _messageController.clear();
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Échec de l\'envoi du message');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    return timestamp != null
        ? DateFormat.Hm().format(timestamp.toDate())
        : '';
  }

  String _formatDateHeader(DateTime date) {
    if (!_isDateFormatInitialized) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAfter(today)) return "Aujourd'hui";
    if (date.isAfter(yesterday)) return "Hier";

    return DateFormat('EEEE d MMMM', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final onPrimaryColor = theme.colorScheme.onPrimary;
    final surfaceColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final secondaryColor = isDarkMode ? Colors.blueGrey[700]! : Colors.blueGrey[100]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 1,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        title: Row(
          children: [
            Hero(
              tag: 'avatar-${widget.receiverId}',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                backgroundImage: widget.receiverImage != null
                    ? CachedNetworkImageProvider(widget.receiverImage!)
                    : null,
                child: widget.receiverImage == null
                    ? Icon(Icons.person, color: Colors.grey[500])
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.receiverName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  StreamBuilder<DocumentSnapshot>(
                    stream: _chatService.getUserStatusStream(widget.receiverId),
                    builder: (context, snapshot) {
                      bool isOnline = false;
                      DateTime? lastSeen;

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        isOnline = data?['isOnline'] ?? false;
                        lastSeen = (data?['lastSeen'] as Timestamp?)?.toDate();
                      }

                      return Text(
                        isOnline
                            ? "En ligne"
                            : lastSeen != null
                            ? "Vu ${DateFormat.Hm().format(lastSeen)}"
                            : "Hors ligne",
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: isDarkMode ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [Colors.grey[850]!, Colors.grey[900]!]
                  : [Colors.grey[100]!, Colors.grey[200]!],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessages(_conversationId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Erreur de chargement des messages',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingMessages(isDarkMode);
                    }

                    final messages = snapshot.data?.docs ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 20),
                            Text(
                              'Commencez la conversation',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Envoyez votre premier message à ${widget.receiverName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    _messageIndexMap.clear();
                    int itemIndex = 0;
                    DateTime? lastDate;
                    List<Widget> messageWidgets = [];

                    for (var message in messages) {
                      final data = message.data() as Map<String, dynamic>;
                      final Timestamp? timestamp = data['timestamp'];
                      if (timestamp == null) continue;

                      final messageDate = timestamp.toDate();
                      final messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);
                      final isMe = data['senderId'] == widget.currentUser.id;

                      if (lastDate == null || !DateUtils.isSameDay(lastDate, messageDay)) {
                        lastDate = messageDay;
                        final headerWidget = _buildDateHeader(
                          _formatDateHeader(messageDay),
                          isDarkMode,
                          key: ValueKey('header-${message.id}'),
                        );
                        messageWidgets.add(
                          AutoScrollTag(
                            key: ValueKey('header-$itemIndex'),
                            controller: _scrollController,
                            index: itemIndex,
                            child: headerWidget,
                          ),
                        );
                        _messageIndexMap['header-${message.id}'] = itemIndex++;
                      }

                      final messageWidget = _buildMessageBubble(
                        data,
                        isMe,
                        primaryColor,
                        onPrimaryColor,
                        isDarkMode,
                        key: ValueKey('msg-${message.id}'),
                      );
                      messageWidgets.add(
                        AutoScrollTag(
                          key: ValueKey('msg-$itemIndex'),
                          controller: _scrollController,
                          index: itemIndex,
                          child: messageWidget,
                        ),
                      );
                      _messageIndexMap['msg-${message.id}'] = itemIndex++;
                    }

                    messageWidgets.add(
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('conversations')
                            .doc(_conversationId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final typing = snapshot.data!.data() as Map<String, dynamic>?;
                            if (typing?[widget.receiverId] == true) {
                              return _buildTypingIndicator(isDarkMode);
                            }
                          }
                          return const SizedBox(height: 8);
                        },
                      ),
                    );

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.only(top: 16, bottom: 80, left: 8, right: 8),
                      itemCount: messageWidgets.length,
                      itemBuilder: (context, index) => messageWidgets[index],
                    );
                  },
                ),
              ),
              _buildMessageInput(theme, isDarkMode, secondaryColor),
            ],
          ),
        ),
      ),
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton.small(
        backgroundColor: primaryColor,
        onPressed: _scrollToBottom,
        child: Icon(Icons.arrow_downward, color: onPrimaryColor),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }

  Widget _buildLoadingMessages(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final isMe = index % 3 == 0;
        return Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  const CircleAvatar(radius: 18, backgroundColor: Colors.white),
                Container(
                  width: MediaQuery.of(context).size.width * (isMe ? 0.6 : 0.7),
                  margin: EdgeInsets.only(
                    left: isMe ? 0 : 8,
                    right: isMe ? 8 : 0,
                    top: 4,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Container(
                          width: 100,
                          height: 12,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 10,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(String date, bool isDarkMode, {Key? key}) {
    return Center(
      key: key,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.blueGrey[700] : Colors.blueGrey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          date,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.blueGrey[200] : Colors.blueGrey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.blueGrey[700] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimatedDot(isDarkMode, 0),
          _buildAnimatedDot(isDarkMode, 200),
          _buildAnimatedDot(isDarkMode, 400),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(bool isDarkMode, int delayMillis) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delayMillis)),
      builder: (context, snapshot) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.blueGrey[200] : Colors.blueGrey[600],
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> data,
      bool isMe,
      Color bubbleColor,
      Color textColor,
      bool isDarkMode, {
        Key? key,
      }) {
    final message = data['message']?.toString() ?? '';
    final status = data['status'] as String? ?? 'sent';
    final Timestamp? timestamp = data['timestamp'];
    final time = timestamp != null ? _formatTime(timestamp) : '';

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              backgroundImage: data['senderImage'] != null
                  ? CachedNetworkImageProvider(data['senderImage'].toString())
                  : null,
              child: data['senderImage'] == null
                  ? Icon(Icons.person, size: 14, color: Colors.grey[500])
                  : null,
            ),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: !isMe ? 8 : 0,
                right: isMe ? 8 : 0,
              ),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Material(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    elevation: 1,
                    color: isMe ? bubbleColor : isDarkMode ? Colors.grey[800] : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                data['senderName']?.toString() ?? 'Inconnu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isMe
                                      ? textColor.withOpacity(0.8)
                                      : (isDarkMode ? Colors.blueGrey[200] : Colors.blueGrey[700]),
                                ),
                              ),
                            ),
                          Text(
                            message,
                            style: TextStyle(
                              color: isMe ? textColor : (isDarkMode ? Colors.white : Colors.black87),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Icon(
                            status == 'read'
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 14,
                            color: status == 'read'
                                ? Colors.blue
                                : Colors.grey[500],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme, bool isDarkMode, Color secondaryColor) {
    final primaryColor = theme.primaryColor;
    final onPrimaryColor = theme.colorScheme.onPrimary;

    return Form(
      key: _messageFormKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add, color: primaryColor, size: 28),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Écrivez un message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Message requis';
                          }
                          return null;
                        },
                        onChanged: _onTypingChanged,
                        onFieldSubmitted: (text) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.emoji_emotions, color: primaryColor),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: primaryColor),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: _isTyping ? primaryColor : Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _isTyping && !_isSending ? _sendMessage : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: _isSending
                      ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onPrimaryColor,
                    ),
                  )
                      : Icon(
                    Icons.send_rounded,
                    color: _isTyping ? onPrimaryColor : primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}