import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BoutiqueHelpScreen extends StatefulWidget {
  BoutiqueHelpScreen({Key? key}) : super(key: key);

  @override
  _BoutiqueHelpScreenState createState() => _BoutiqueHelpScreenState();
}

class _BoutiqueHelpScreenState extends State<BoutiqueHelpScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _fadeController;
  late Animation<double> _headerAnimation;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Comment ajouter de nouveaux produits ?',
      'answer': 'Accédez à l\'écran des produits et appuyez sur le bouton "+". Remplissez les détails du produit incluant nom, description, prix, catégorie et images. Vous pouvez également gérer le stock et définir des variantes.',
      'category': 'Produits',
      'icon': Icons.add_box,
      'color': Color(0xFF4CAF50),
    },
    {
      'question': 'Comment gérer les commandes ?',
      'answer': 'L\'écran des commandes vous permet de voir toutes les commandes avec filtres par statut (en attente, confirmée, expédiée, livrée). Vous pouvez mettre à jour l\'état, ajouter des notes et contacter les clients.',
      'category': 'Commandes',
      'icon': Icons.shopping_cart,
      'color': Color(0xFF2196F3),
    },
    {
      'question': 'Comment modifier mes informations de boutique ?',
      'answer': 'Accédez aux paramètres pour modifier le nom, la description, l\'adresse, horaires d\'ouverture, coordonnées et logo de votre boutique. Ces informations sont visibles par vos clients.',
      'category': 'Paramètres',
      'icon': Icons.store,
      'color': Color(0xFF9C27B0),
    },
    {
      'question': 'Comment créer des promotions ?',
      'answer': 'Dans l\'écran des promotions, créez des offres spéciales avec pourcentage de réduction, dates de validité, conditions d\'application et produits concernés. Vous pouvez aussi créer des codes promo.',
      'category': 'Promotions',
      'icon': Icons.local_offer,
      'color': Color(0xFFFF9800),
    },
    {
      'question': 'Comment répondre aux avis clients ?',
      'answer': 'Accédez à l\'écran des avis pour voir tous les commentaires et notes. Répondez professionnellement aux avis, remerciez les clients satisfaits et résolvez les problèmes mentionnés.',
      'category': 'Avis',
      'icon': Icons.star,
      'color': Color(0xFFF44336),
    },
    {
      'question': 'Comment gérer mes finances ?',
      'answer': 'Consultez le tableau de bord financier pour voir vos revenus, dépenses, bénéfices et rapports détaillés. Vous pouvez exporter les données pour votre comptabilité.',
      'category': 'Finances',
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFF607D8B),
    },
    {
      'question': 'Comment optimiser ma boutique ?',
      'answer': 'Utilisez les statistiques pour analyser vos ventes, produits populaires et comportement clients. Mettez à jour régulièrement vos produits et descriptions.',
      'category': 'Optimisation',
      'icon': Icons.trending_up,
      'color': Color(0xFF795548),
    },
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'Tutoriel vidéo',
      'subtitle': 'Regarder les guides',
      'icon': Icons.play_circle_filled,
      'color': Color(0xFFE91E63),
      'action': 'video',
    },
    {
      'title': 'Chat en direct',
      'subtitle': 'Support instantané',
      'icon': Icons.chat,
      'color': Color(0xFF00BCD4),
      'action': 'chat',
    },
    {
      'title': 'Planifier un appel',
      'subtitle': 'Assistance personnalisée',
      'icon': Icons.calendar_today,
      'color': Color(0xFF8BC34A),
      'action': 'schedule',
    },
    {
      'title': 'Base de connaissances',
      'subtitle': 'Documentation complète',
      'icon': Icons.library_books,
      'color': Color(0xFF3F51B5),
      'action': 'knowledge',
    },
  ];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _headerController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs.where((faq) {
      return faq['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['category'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void openWhatsApp(BuildContext context, String phoneNumber) async {
    final whatsappUrl = Uri.parse('whatsapp://send?phone=$phoneNumber&text=Bonjour, j\'ai besoin d\'aide avec ElegantFaso');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      _showError(context, 'WhatsApp n\'est pas installé ou ne peut pas être ouvert.');
    }
  }

  void _handleContactTap(BuildContext context, String contact) {
    if (contact.contains('@')) {
      _sendEmail(context, contact);
    } else if (contact.contains('+')) {
      _makePhoneCall(context, contact);
    } else {
      _openWebsite(context);
    }
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'video':
        _openWebsite(context);
        break;
      case 'chat':
        openWhatsApp(context, '+22652294398');
        break;
      case 'schedule':
        _sendEmail(context, 'support@elegantfaso.com');
        break;
      case 'knowledge':
        _openWebsite(context);
        break;
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support ElegantFaso&body=Bonjour,%0D%0A%0D%0AJ\'ai besoin d\'aide concernant:%0D%0A%0D%0ACordialement,',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showError(context, 'Impossible d\'ouvrir l\'application email');
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showError(context, 'Impossible de passer un appel');
    }
  }

  Future<void> _openWebsite(BuildContext context) async {
    final Uri webUri = Uri.parse('https://www.elegantfaso.com');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri);
    } else {
      _showError(context, 'Impossible d\'ouvrir le site web');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Aide et Support', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _headerAnimation.value)),
                      child: Opacity(
                        opacity: _headerAnimation.value.clamp(0.0, 1.0),
                        child: _buildSupportCard(context),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildQuickActions(),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildFaqSection(),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContactSection(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Rechercher dans l\'aide...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6A11CB).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.support_agent, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Support 24/7',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notre équipe est disponible à tout moment pour vous accompagner dans votre réussite',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => openWhatsApp(context, '+22652294398'),
              icon: Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF6A11CB)),
              label: Text('Contacter via WhatsApp', style: TextStyle(color: Color(0xFF6A11CB))),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3, // Réduit pour donner plus d'espace vertical
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleQuickAction(action['action']),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12), // Réduit le padding
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // Ajouté pour éviter le débordement
                      children: [
                        Icon(
                          action['icon'],
                          size: 28, // Réduit la taille de l'icône
                          color: action['color'],
                        ),
                        SizedBox(height: 6), // Réduit l'espacement
                        Flexible( // Ajouté pour gérer le débordement
                          child: Text(
                            action['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13, // Réduit la taille de police
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1, // Limite à une ligne
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 2), // Réduit l'espacement
                        Flexible( // Ajouté pour gérer le débordement
                          child: Text(
                            action['subtitle'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11, // Réduit la taille de police
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2, // Limite à deux lignes
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions fréquentes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        if (_filteredFaqs.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Aucun résultat trouvé',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Essayez un autre terme de recherche',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          ..._filteredFaqs.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: _buildFaqItem(faq, index),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildFaqItem(Map<String, dynamic> faq, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: faq['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            faq['icon'],
            color: faq['color'],
            size: 20,
          ),
        ),
        title: Text(
          faq['question'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            faq['category'],
            style: TextStyle(
              color: faq['color'],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        children: [
          Text(
            faq['answer'],
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Autres moyens de contact',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        _buildContactButton(
          context,
          'support@elegantfaso.com',
          Icons.email,
          'Email',
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildContactButton(
          context,
          '+226 05 67 09 81',
          Icons.phone,
          'Téléphone',
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildContactButton(
          context,
          'Visiter notre site web',
          Icons.language,
          'Site Web',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildContactButton(
      BuildContext context,
      String text,
      IconData icon,
      String label,
      Color color,
      ) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: color),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            Text(
              text,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        onPressed: () => _handleContactTap(context, text),
      ),
    );
  }
}