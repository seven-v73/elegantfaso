import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SerpApiService {
  final String _apiKey = dotenv.env['SERP_API_KEY'] ?? '';
  final String _baseUrl = 'https://serpapi.com/search.json';

  // Cache pour éviter les appels répétés
  final Map<String, Map<String, dynamic>> _cache = {};
  static const int _cacheExpiration = 300; // 5 minutes

  // Configuration du scraping
  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
  };

  // Sites prioritaires pour le scraping
  final List<String> _prioritySites = [
    'fashionnetwork.com',
    'vogue.fr',
    'vogue.com',
    'elle.fr',
    'marieclaire.fr',
    'businessoffashion.com',
    'thecut.com',
    'afrik.com',
    'jeuneafrique.com',
  ];

  // Méthode principale hybride (API + Scraping)
  Future<Map<String, dynamic>> hybridSearch(String query) async {
    try {
      // Essayer d'abord l'API si disponible
      if (_apiKey.isNotEmpty) {
        final apiResult = await intelligentSearch(query);
        if (apiResult['success'] == true) {
          return apiResult;
        }
      }

      // Fallback vers le scraping
      debugPrint('API indisponible, basculement vers le scraping...');
      return await intelligentScraping(query);
    } catch (e) {
      debugPrint('Erreur recherche hybride: $e');
      return {'error': 'Impossible de récupérer les informations'};
    }
  }

  // Méthode de scraping intelligent
  Future<Map<String, dynamic>> intelligentScraping(String query) async {
    try {
      final searchType = _detectSearchType(query);
      List<Future<Map<String, dynamic>>> scrapes = [];

      switch (searchType) {
        case 'news':
          scrapes.add(scrapeFashionNews(query));
          scrapes.add(scrapeGlobalFashionNews(query));
          break;
        case 'events':
          scrapes.add(scrapeCulturalEvents(query));
          scrapes.add(scrapeLocalEvents(query));
          break;
        case 'shopping':
          scrapes.add(scrapePrices(query));
          scrapes.add(scrapeShopping(query));
          break;
        case 'weather':
          scrapes.add(scrapeWeather(query));
          break;
        case 'comprehensive':
          scrapes.add(scrapeFashionNews(query));
          scrapes.add(scrapeGeneralFashion(query));
          break;
        default:
          scrapes.add(scrapeGeneralFashion(query));
      }

      final results = await Future.wait(scrapes);
      return _combineSearchResults(results, searchType);
    } catch (e) {
      debugPrint('Erreur scraping intelligent: $e');
      return {'error': 'Impossible de récupérer les informations via scraping'};
    }
  }

  // Scraping des actualités mode
  Future<Map<String, dynamic>> scrapeFashionNews(String query) async {
    final cacheKey = 'scrape_news_$query';
    if (_isInCache(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final results = <Map<String, dynamic>>[];

      // Scraper Google News
      final googleResults = await _scrapeGoogleNews(query);
      results.addAll(googleResults);

      // Scraper sites spécialisés
      final specializedResults = await _scrapeSpecializedSites(
        query,
        'fashion',
      );
      results.addAll(specializedResults);

      final processedResults = {
        'success': true,
        'results': results.take(6).toList(),
        'type': 'scraped_news',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      _cache[cacheKey] = processedResults;
      return processedResults;
    } catch (e) {
      debugPrint('Erreur scraping news: $e');
      return {'error': 'Impossible de scraper les actualités'};
    }
  }

  // Compatibility alias: older callers now receive global fashion news.
  Future<Map<String, dynamic>> scrapeBurkinaNews(String query) =>
      scrapeGlobalFashionNews(query);

  Future<Map<String, dynamic>> scrapeGlobalFashionNews(String query) async {
    try {
      final results = <Map<String, dynamic>>[];
      final fashionSites = [
        'fashionnetwork.com',
        'vogue.fr',
        'elle.fr',
        'afrik.com',
      ];

      for (final site in fashionSites) {
        try {
          final siteResults = await _scrapeWebsite(
            site,
            '$query mode fashion style créateurs monde Afrique Europe Asie Amériques',
          );
          results.addAll(siteResults);
        } catch (e) {
          debugPrint('Erreur scraping $site: $e');
        }
      }

      return {
        'success': true,
        'results': results.take(5).toList(),
        'type': 'global_fashion_news',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      debugPrint('Erreur scraping global fashion news: $e');
      return {'error': 'Impossible de scraper les actualités mode'};
    }
  }

  // Scraping des événements culturels
  Future<Map<String, dynamic>> scrapeCulturalEvents(String query) async {
    try {
      final results = <Map<String, dynamic>>[];

      // Scraper les sites d'événements
      final eventSites = ['africanews.com', 'rfi.fr', 'bbc.com'];

      for (final site in eventSites) {
        try {
          final siteResults = await _scrapeWebsite(
            site,
            '$query événement mode culture créateurs local international',
          );
          results.addAll(siteResults);
        } catch (e) {
          debugPrint('Erreur scraping events $site: $e');
        }
      }

      return {
        'success': true,
        'results': results.take(4).toList(),
        'type': 'cultural_events',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      debugPrint('Erreur scraping cultural events: $e');
      return {'error': 'Impossible de scraper les événements culturels'};
    }
  }

  // Scraping des événements locaux et internationaux
  Future<Map<String, dynamic>> scrapeLocalEvents(String query) async {
    try {
      final results = <Map<String, dynamic>>[];

      final localSites = ['afrik.com', 'rfi.fr', 'bbc.com'];

      for (final site in localSites) {
        try {
          final siteResults = await _scrapeWebsite(site, query);
          results.addAll(siteResults);
        } catch (e) {
          debugPrint('Erreur scraping local $site: $e');
        }
      }

      return {
        'success': true,
        'results': results.take(3).toList(),
        'type': 'local_events',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      debugPrint('Erreur scraping local events: $e');
      return {'error': 'Impossible de scraper les événements locaux'};
    }
  }

  // Scraping des prix
  Future<Map<String, dynamic>> scrapePrices(String query) async {
    try {
      final results = <Map<String, dynamic>>[];

      // Scraper les sites de e-commerce et marketplaces
      final commerceSites = ['jumia.ci', 'afrimarket.com', 'amazon.fr'];

      for (final site in commerceSites) {
        try {
          final siteResults = await _scrapeWebsite(site, '$query prix');
          results.addAll(siteResults);
        } catch (e) {
          debugPrint('Erreur scraping prices $site: $e');
        }
      }

      return {
        'success': true,
        'results': results.take(4).toList(),
        'type': 'prices',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      debugPrint('Erreur scraping prices: $e');
      return {'error': 'Impossible de scraper les prix'};
    }
  }

  // Scraping du shopping
  Future<Map<String, dynamic>> scrapeShopping(String query) async {
    try {
      final results = <Map<String, dynamic>>[];

      // Sites shopping africains
      final shoppingSites = ['jumia.ci', 'afrimarket.com', 'kaymu.com'];

      for (final site in shoppingSites) {
        try {
          final siteResults = await _scrapeShopping(site, query);
          results.addAll(siteResults);
        } catch (e) {
          debugPrint('Erreur scraping shopping $site: $e');
        }
      }

      return {
        'success': true,
        'results': results.take(4).toList(),
        'type': 'shopping',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      debugPrint('Erreur scraping shopping: $e');
      return {'error': 'Impossible de scraper le shopping'};
    }
  }

  // Scraping de la météo
  Future<Map<String, dynamic>> scrapeWeather(String query) async {
    try {
      final results = <Map<String, dynamic>>[];

      // Sites météo
      final weatherSites = ['weather.com', 'meteo.bf', 'accuweather.com'];

      for (final site in weatherSites) {
        try {
          final siteResults = await _scrapeWeatherSite(site, query);
          results.addAll(siteResults);
        } catch (e) {
          debugPrint('Erreur scraping weather $site: $e');
        }
      }

      return {
        'success': true,
        'results': results.take(3).toList(),
        'type': 'weather',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      debugPrint('Erreur scraping weather: $e');
      return {'error': 'Impossible de scraper la météo'};
    }
  }

  // Scraping mode général
  Future<Map<String, dynamic>> scrapeGeneralFashion(String query) async {
    try {
      final results = <Map<String, dynamic>>[];

      // Scraper différents types de sites
      final fashionResults = await _scrapeSpecializedSites(query, 'fashion');
      results.addAll(fashionResults);

      final blogResults = await _scrapeFashionBlogs(query);
      results.addAll(blogResults);

      return {
        'success': true,
        'results': results.take(6).toList(),
        'type': 'general_fashion',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      debugPrint('Erreur scraping general fashion: $e');
      return {'error': 'Impossible de scraper les informations mode'};
    }
  }

  // Méthodes de scraping spécialisées

  Future<List<Map<String, dynamic>>> _scrapeGoogleNews(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(
        '$query actualités mode africaine',
      );
      final url =
          'https://news.google.com/search?q=$encodedQuery&hl=fr&gl=bf&ceid=BF:fr';

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final results = <Map<String, dynamic>>[];

        final articles = document.querySelectorAll('article');

        for (final article in articles.take(5)) {
          final titleElement = article.querySelector('h3, .JtKRv');
          final linkElement = article.querySelector('a');
          final timeElement = article.querySelector('time');

          if (titleElement != null && linkElement != null) {
            results.add({
              'title': titleElement.text.trim(),
              'link': _buildFullUrl(
                linkElement.attributes['href'] ?? '',
                'news.google.com',
              ),
              'snippet': _extractSnippet(article),
              'source': 'Google News',
              'date': timeElement?.text.trim() ?? 'Date inconnue',
              'type': 'news_scraped',
              'relevance': _calculateRelevance(
                titleElement.text,
                _extractSnippet(article),
              ),
            });
          }
        }

        return results;
      }

      return [];
    } catch (e) {
      debugPrint('Erreur scraping Google News: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _scrapeSpecializedSites(
    String query,
    String category,
  ) async {
    final results = <Map<String, dynamic>>[];
    final fashionSites = ['fashionnetwork.com', 'vogue.fr', 'elle.fr'];

    for (final site in fashionSites) {
      try {
        final siteResults = await _scrapeWebsite(site, query);
        results.addAll(siteResults);
      } catch (e) {
        debugPrint('Erreur scraping $site: $e');
      }

      // Délai entre requêtes pour éviter le rate limiting
      await Future.delayed(Duration(milliseconds: 500));
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _scrapeFashionBlogs(String query) async {
    final results = <Map<String, dynamic>>[];
    final blogSites = ['hypebae.com', 'whowhatwear.com', 'refinery29.com'];

    for (final site in blogSites) {
      try {
        final siteResults = await _scrapeWebsite(
          site,
          '$query african fashion',
        );
        results.addAll(siteResults);
      } catch (e) {
        debugPrint('Erreur scraping blog $site: $e');
      }

      await Future.delayed(Duration(milliseconds: 500));
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _scrapeWebsite(
    String site,
    String query,
  ) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final searchUrl = 'https://$site/search?q=$encodedQuery';

      final response = await http.get(Uri.parse(searchUrl), headers: _headers);

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        return _extractContentFromDocument(document, site);
      }

      return [];
    } catch (e) {
      debugPrint('Erreur scraping $site: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _scrapeShopping(
    String site,
    String query,
  ) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final searchUrl = 'https://$site/search?q=$encodedQuery';

      final response = await http.get(Uri.parse(searchUrl), headers: _headers);

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        return _extractShoppingFromDocument(document, site);
      }

      return [];
    } catch (e) {
      debugPrint('Erreur scraping shopping $site: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _scrapeWeatherSite(
    String site,
    String query,
  ) async {
    try {
      final encodedQuery = Uri.encodeComponent(
        query.trim().isEmpty ? 'local weather' : '$query weather',
      );
      final weatherUrl = 'https://$site/search?q=$encodedQuery';

      final response = await http.get(Uri.parse(weatherUrl), headers: _headers);

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        return _extractWeatherFromDocument(document, site);
      }

      return [];
    } catch (e) {
      debugPrint('Erreur scraping weather $site: $e');
      return [];
    }
  }

  // Méthodes d'extraction de contenu

  List<Map<String, dynamic>> _extractContentFromDocument(
    dom.Document document,
    String site,
  ) {
    final results = <Map<String, dynamic>>[];

    // Sélecteurs génériques pour différents types de contenu
    final selectors = [
      'article',
      '.article',
      '[data-testid="article"]',
      '.post',
      '.entry',
      '.content-item',
      '.search-result',
      '.result-item',
      'h2, h3, h4',
      '.title',
      '.headline',
    ];

    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);

      for (final element in elements.take(3)) {
        final title = _extractTitle(element);
        final link = _extractLink(element);
        final snippet = _extractSnippet(element);

        if (title.isNotEmpty && link.isNotEmpty) {
          results.add({
            'title': title,
            'link': _buildFullUrl(link, site),
            'snippet': snippet,
            'source': site,
            'type': 'scraped_content',
            'relevance': _calculateRelevance(title, snippet),
          });
        }
      }

      if (results.isNotEmpty) break;
    }

    return results;
  }

  List<Map<String, dynamic>> _extractShoppingFromDocument(
    dom.Document document,
    String site,
  ) {
    final results = <Map<String, dynamic>>[];

    final productSelectors = [
      '.product',
      '.item',
      '.product-item',
      '[data-testid="product"]',
      '.listing-item',
    ];

    for (final selector in productSelectors) {
      final elements = document.querySelectorAll(selector);

      for (final element in elements.take(4)) {
        final title = _extractTitle(element);
        final link = _extractLink(element);
        final price = _extractPrice(element.text);

        if (title.isNotEmpty) {
          results.add({
            'title': title,
            'link': _buildFullUrl(link, site),
            'snippet': _extractSnippet(element),
            'source': site,
            'price': price,
            'type': 'shopping_scraped',
          });
        }
      }

      if (results.isNotEmpty) break;
    }

    return results;
  }

  List<Map<String, dynamic>> _extractWeatherFromDocument(
    dom.Document document,
    String site,
  ) {
    final results = <Map<String, dynamic>>[];

    final weatherSelectors = [
      '.weather',
      '.forecast',
      '.current-weather',
      '[data-testid="weather"]',
      '.temperature',
    ];

    for (final selector in weatherSelectors) {
      final elements = document.querySelectorAll(selector);

      for (final element in elements.take(2)) {
        final extractedTitle = _extractTitle(element);
        final title =
            extractedTitle.isEmpty ? 'Météo de votre zone' : extractedTitle;
        final temperature = _extractTemperature(element);

        if (temperature.isNotEmpty) {
          results.add({
            'title': title,
            'link': _buildFullUrl('', site),
            'snippet': _extractSnippet(element),
            'source': site,
            'temperature': temperature,
            'type': 'weather_scraped',
          });
        }
      }

      if (results.isNotEmpty) break;
    }

    return results;
  }

  // Méthodes utilitaires d'extraction

  String _extractTitle(dom.Element element) {
    final titleSelectors = [
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      '.title',
      '.headline',
      '.article-title',
      '[data-testid="title"]',
      '.post-title',
    ];

    for (final selector in titleSelectors) {
      final titleElement = element.querySelector(selector);
      if (titleElement != null && titleElement.text.trim().isNotEmpty) {
        return titleElement.text.trim();
      }
    }

    // Fallback: utiliser le texte de l'élément lui-même s'il est court
    final text = element.text.trim();
    if (text.length < 200) {
      return text;
    }

    return '';
  }

  String _extractLink(dom.Element element) {
    final linkSelectors = ['a', '[href]'];

    for (final selector in linkSelectors) {
      final linkElement = element.querySelector(selector);
      if (linkElement != null) {
        return linkElement.attributes['href'] ?? '';
      }
    }

    return '';
  }

  String _extractSnippet(dom.Element element) {
    final snippetSelectors = [
      'p',
      '.excerpt',
      '.summary',
      '.description',
      '.content',
      '.snippet',
      '.preview',
    ];

    for (final selector in snippetSelectors) {
      final snippetElement = element.querySelector(selector);
      if (snippetElement != null && snippetElement.text.trim().isNotEmpty) {
        return _cleanSnippet(snippetElement.text.trim());
      }
    }

    // Fallback: utiliser le texte de l'élément avec limitation
    final text = element.text.trim();
    if (text.length > 50) {
      return _cleanSnippet('${text.substring(0, 200)}...');
    }

    return '';
  }

  String _extractTemperature(dom.Element element) {
    final tempRegex = RegExp(r'(-?\d+)°?[CF]?');
    final match = tempRegex.firstMatch(element.text);

    if (match != null) {
      return '${match.group(1)}°C';
    }

    return '';
  }

  String _buildFullUrl(String path, String domain) {
    if (path.startsWith('http')) {
      return path;
    }

    if (path.startsWith('/')) {
      return 'https://$domain$path';
    }

    return 'https://$domain/$path';
  }

  // Méthodes de l'API originale (héritées)
  Future<Map<String, dynamic>> intelligentSearch(String query) async {
    try {
      final searchType = _detectSearchType(query);
      List<Future<Map<String, dynamic>>> searches = [];

      switch (searchType) {
        case 'news':
          searches.add(searchFashionNews(query));
          searches.add(searchGeneralFashion(query));
          break;
        case 'events':
          searches.add(searchCulturalEvents(query));
          searches.add(searchLocalEvents(query));
          break;
        case 'shopping':
          searches.add(searchPrices(query));
          searches.add(searchShopping(query));
          break;
        case 'weather':
          searches.add(searchWeather(query));
          break;
        case 'comprehensive':
          searches.add(searchFashionNews(query));
          searches.add(searchGeneralFashion(query));
          searches.add(searchImages(query));
          break;
        default:
          searches.add(searchGeneralFashion(query));
      }

      final results = await Future.wait(searches);
      return _combineSearchResults(results, searchType);
    } catch (e) {
      debugPrint('Erreur recherche intelligente: $e');
      return {
        'error': 'Impossible de récupérer les informations pour le moment',
      };
    }
  }

  String _detectSearchType(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('actualité') ||
        lowerQuery.contains('news') ||
        lowerQuery.contains('récent') ||
        lowerQuery.contains('dernier') ||
        lowerQuery.contains('nouveau')) {
      return 'news';
    }

    if (lowerQuery.contains('événement') ||
        lowerQuery.contains('festival') ||
        lowerQuery.contains('salon') ||
        lowerQuery.contains('défilé') ||
        lowerQuery.contains('fespaco') ||
        lowerQuery.contains('siao')) {
      return 'events';
    }

    if (lowerQuery.contains('prix') ||
        lowerQuery.contains('coût') ||
        lowerQuery.contains('acheter') ||
        lowerQuery.contains('boutique') ||
        lowerQuery.contains('magasin') ||
        lowerQuery.contains('où acheter')) {
      return 'shopping';
    }

    if (lowerQuery.contains('météo') ||
        lowerQuery.contains('temps') ||
        lowerQuery.contains('climat') ||
        lowerQuery.contains('température')) {
      return 'weather';
    }

    if (lowerQuery.contains('?') ||
        lowerQuery.contains('comment') ||
        lowerQuery.contains('quoi') ||
        lowerQuery.contains('tendance')) {
      return 'comprehensive';
    }

    return 'general';
  }

  // Méthodes API (conservées pour compatibilité)
  Future<Map<String, dynamic>> searchFashionNews(String query) async {
    if (_apiKey.isEmpty) {
      return await scrapeFashionNews(query);
    }

    final cacheKey = 'news_$query';
    if (_isInCache(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final searchQuery = _buildFashionQuery(
        query,
        'actualités mode africaine',
      );

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': searchQuery,
          'api_key': _apiKey,
          'engine': 'google',
          'gl': 'bf',
          'hl': 'fr',
          'num': '8',
          'tbm': 'nws',
          'sort': 'date',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = _processNewsResults(data);
        _cache[cacheKey] = result;
        return result;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur SerpApi News: $e');
      return await scrapeFashionNews(query);
    }
  }

  Future<Map<String, dynamic>> searchGeneralFashion(String query) async {
    if (_apiKey.isEmpty) {
      return await scrapeGeneralFashion(query);
    }

    final cacheKey = 'fashion_$query';
    if (_isInCache(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final searchQuery = _buildFashionQuery(
        query,
        'mode internationale Afrique Europe Asie Amériques créateurs textiles',
      );

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': searchQuery,
          'api_key': _apiKey,
          'engine': 'google',
          'gl': 'bf',
          'hl': 'fr',
          'num': '8',
          'safe': 'active',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = _processGeneralResults(data);
        _cache[cacheKey] = result;
        return result;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur SerpApi Fashion: $e');
      return await scrapeGeneralFashion(query);
    }
  }

  Future<Map<String, dynamic>> searchCulturalEvents(String query) async {
    if (_apiKey.isEmpty) {
      return await scrapeCulturalEvents(query);
    }

    final cacheKey = 'events_$query';
    if (_isInCache(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final searchQuery = _buildEventQuery(query);

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': searchQuery,
          'api_key': _apiKey,
          'engine': 'google',
          'gl': 'bf',
          'hl': 'fr',
          'num': '6',
          'tbm': 'nws',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = _processEventResults(data);
        _cache[cacheKey] = result;
        return result;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur SerpApi Events: $e');
      return await scrapeCulturalEvents(query);
    }
  }

  Future<Map<String, dynamic>> searchLocalEvents(String query) async {
    if (_apiKey.isEmpty) {
      return await scrapeLocalEvents(query);
    }

    try {
      final searchQuery =
          'événements mode culture créateurs local international $query';

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': searchQuery,
          'api_key': _apiKey,
          'engine': 'google',
          'gl': 'bf',
          'hl': 'fr',
          'num': '5',
          'tbm': 'nws',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _processLocalEventResults(data);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur SerpApi Local Events: $e');
      return await scrapeLocalEvents(query);
    }
  }

  Future<Map<String, dynamic>> searchPrices(String query) async {
    if (_apiKey.isEmpty) {
      return await scrapePrices(query);
    }

    final cacheKey = 'prices_$query';
    if (_isInCache(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final searchQuery = '$query prix shopping mode international';

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': searchQuery,
          'api_key': _apiKey,
          'engine': 'google_shopping',
          'gl': 'bf',
          'hl': 'fr',
          'num': '6',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = _processPriceResults(data);
        _cache[cacheKey] = result;
        return result;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur SerpApi Prices: $e');
      return await scrapePrices(query);
    }
  }

  Future<Map<String, dynamic>> searchShopping(String query) async {
    if (_apiKey.isEmpty) {
      return await scrapeShopping(query);
    }

    try {
      final searchQuery = '$query shopping mode Afrique Europe Asie Amériques';

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': searchQuery,
          'api_key': _apiKey,
          'engine': 'google',
          'gl': 'bf',
          'hl': 'fr',
          'num': '6',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _processShoppingResults(data);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur SerpApi Shopping: $e');
      return await scrapeShopping(query);
    }
  }

  Future<Map<String, dynamic>> searchWeather(String query) async {
    if (_apiKey.isEmpty) {
      return await scrapeWeather(query);
    }

    try {
      final searchQuery =
          query.trim().isEmpty ? 'météo locale' : 'météo $query';

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': searchQuery,
          'api_key': _apiKey,
          'engine': 'google',
          'gl': 'bf',
          'hl': 'fr',
          'num': '3',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _processWeatherResults(data);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur SerpApi Weather: $e');
      return await scrapeWeather(query);
    }
  }

  Future<Map<String, dynamic>> searchImages(String query) async {
    if (_apiKey.isEmpty) {
      return {
        'success': false,
        'message': 'API non disponible pour les images',
      };
    }

    final cacheKey = 'images_$query';
    if (_isInCache(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final searchQuery = _buildFashionQuery(
        query,
        'mode internationale street style couture textiles culturels',
      );

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': searchQuery,
          'api_key': _apiKey,
          'engine': 'google',
          'gl': 'bf',
          'hl': 'fr',
          'tbm': 'isch',
          'num': '6',
          'safe': 'active',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = _processImageResults(data);
        _cache[cacheKey] = result;
        return result;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur SerpApi Images: $e');
      return {
        'success': false,
        'message': 'Impossible de récupérer les images',
      };
    }
  }

  // Méthodes de traitement des résultats API

  Map<String, dynamic> _processNewsResults(Map<String, dynamic> data) {
    final newsResults = data['news_results'] as List<dynamic>? ?? [];
    final processedResults =
        newsResults
            .map((item) {
              return {
                'title': item['title'] ?? '',
                'snippet': item['snippet'] ?? '',
                'link': item['link'] ?? '',
                'source': item['source'] ?? '',
                'date': item['date'] ?? '',
                'thumbnail': item['thumbnail'] ?? '',
                'type': 'news',
                'relevance': _calculateRelevance(
                  item['title'] ?? '',
                  item['snippet'] ?? '',
                ),
              };
            })
            .take(6)
            .toList();

    return {
      'success': true,
      'results': processedResults,
      'type': 'news',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> _processGeneralResults(Map<String, dynamic> data) {
    final organicResults = data['organic_results'] as List<dynamic>? ?? [];
    final processedResults =
        organicResults
            .map((item) {
              return {
                'title': item['title'] ?? '',
                'snippet': item['snippet'] ?? '',
                'link': item['link'] ?? '',
                'source': _extractDomain(item['link'] ?? ''),
                'type': 'general',
                'relevance': _calculateRelevance(
                  item['title'] ?? '',
                  item['snippet'] ?? '',
                ),
                'rich_snippet': item['rich_snippet'] ?? {},
              };
            })
            .take(8)
            .toList();

    return {
      'success': true,
      'results': processedResults,
      'type': 'general',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> _processEventResults(Map<String, dynamic> data) {
    final newsResults = data['news_results'] as List<dynamic>? ?? [];
    final processedResults =
        newsResults
            .map((item) {
              return {
                'title': item['title'] ?? '',
                'snippet': item['snippet'] ?? '',
                'link': item['link'] ?? '',
                'source': item['source'] ?? '',
                'date': item['date'] ?? '',
                'type': 'event',
                'relevance': _calculateRelevance(
                  item['title'] ?? '',
                  item['snippet'] ?? '',
                ),
              };
            })
            .take(6)
            .toList();

    return {
      'success': true,
      'results': processedResults,
      'type': 'events',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> _processLocalEventResults(Map<String, dynamic> data) {
    final newsResults = data['news_results'] as List<dynamic>? ?? [];
    final processedResults =
        newsResults
            .map((item) {
              return {
                'title': item['title'] ?? '',
                'snippet': item['snippet'] ?? '',
                'link': item['link'] ?? '',
                'source': item['source'] ?? '',
                'date': item['date'] ?? '',
                'type': 'local_event',
                'relevance': _calculateRelevance(
                  item['title'] ?? '',
                  item['snippet'] ?? '',
                ),
              };
            })
            .take(5)
            .toList();

    return {
      'success': true,
      'results': processedResults,
      'type': 'local_events',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> _processPriceResults(Map<String, dynamic> data) {
    final shoppingResults = data['shopping_results'] as List<dynamic>? ?? [];
    final processedResults =
        shoppingResults
            .map((item) {
              return {
                'title': item['title'] ?? '',
                'snippet': item['snippet'] ?? '',
                'link': item['link'] ?? '',
                'source': item['source'] ?? '',
                'price': item['price'] ?? '',
                'rating': item['rating'] ?? '',
                'reviews': item['reviews'] ?? '',
                'thumbnail': item['thumbnail'] ?? '',
                'type': 'price',
                'relevance': _calculateRelevance(
                  item['title'] ?? '',
                  item['snippet'] ?? '',
                ),
              };
            })
            .take(6)
            .toList();

    return {
      'success': true,
      'results': processedResults,
      'type': 'prices',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> _processShoppingResults(Map<String, dynamic> data) {
    final organicResults = data['organic_results'] as List<dynamic>? ?? [];
    final processedResults =
        organicResults
            .map((item) {
              return {
                'title': item['title'] ?? '',
                'snippet': item['snippet'] ?? '',
                'link': item['link'] ?? '',
                'source': _extractDomain(item['link'] ?? ''),
                'type': 'shopping',
                'relevance': _calculateRelevance(
                  item['title'] ?? '',
                  item['snippet'] ?? '',
                ),
              };
            })
            .take(6)
            .toList();

    return {
      'success': true,
      'results': processedResults,
      'type': 'shopping',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> _processWeatherResults(Map<String, dynamic> data) {
    final organicResults = data['organic_results'] as List<dynamic>? ?? [];
    final answerBox = data['answer_box'] as Map<String, dynamic>? ?? {};

    final processedResults = <Map<String, dynamic>>[];

    // Traiter l'answer box pour la météo
    if (answerBox.isNotEmpty) {
      processedResults.add({
        'title': answerBox['title'] ?? 'Météo de votre zone',
        'snippet': answerBox['snippet'] ?? '',
        'link': answerBox['link'] ?? '',
        'source': 'Google Weather',
        'type': 'weather',
        'weather_data': answerBox,
        'relevance': 10,
      });
    }

    // Traiter les résultats organiques
    final organicWeatherResults =
        organicResults
            .map((item) {
              return {
                'title': item['title'] ?? '',
                'snippet': item['snippet'] ?? '',
                'link': item['link'] ?? '',
                'source': _extractDomain(item['link'] ?? ''),
                'type': 'weather',
                'relevance': _calculateRelevance(
                  item['title'] ?? '',
                  item['snippet'] ?? '',
                ),
              };
            })
            .take(3)
            .toList();

    processedResults.addAll(organicWeatherResults);

    return {
      'success': true,
      'results': processedResults,
      'type': 'weather',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> _processImageResults(Map<String, dynamic> data) {
    final imagesResults = data['images_results'] as List<dynamic>? ?? [];
    final processedResults =
        imagesResults
            .map((item) {
              return {
                'title': item['title'] ?? '',
                'link': item['link'] ?? '',
                'source': item['source'] ?? '',
                'original': item['original'] ?? '',
                'thumbnail': item['thumbnail'] ?? '',
                'type': 'image',
                'relevance': _calculateRelevance(item['title'] ?? '', ''),
              };
            })
            .take(6)
            .toList();

    return {
      'success': true,
      'results': processedResults,
      'type': 'images',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  // Méthodes utilitaires

  String _buildFashionQuery(String query, String context) {
    final fashionTerms = [
      'mode',
      'fashion',
      'style',
      'vêtements',
      'tendance',
      'créateur',
      'designer',
      'couture',
      'textile',
      'tissu',
    ];

    final cultureTerms = [
      'africain',
      'asiatique',
      'européen',
      'américain',
      'oriental',
      'sahel',
      'wax',
      'faso dan fani',
      'bogolan',
      'kente',
      'kimono',
      'sari',
    ];
    final hasCultureContext = cultureTerms.any(
      (term) => query.toLowerCase().contains(term.toLowerCase()),
    );

    final hasContext = fashionTerms.any(
      (term) => query.toLowerCase().contains(term.toLowerCase()),
    );

    if (hasContext || hasCultureContext) {
      return '$query $context';
    }

    return '$query mode internationale créateurs textiles culturels';
  }

  String _buildEventQuery(String query) {
    final eventTerms = [
      'événement',
      'festival',
      'salon',
      'défilé',
      'exposition',
      'fespaco',
      'siao',
      'semaine',
      'journée',
      'célébration',
    ];

    final hasEventContext = eventTerms.any(
      (term) => query.toLowerCase().contains(term.toLowerCase()),
    );

    if (hasEventContext) {
      return '$query mode culture créateurs local international';
    }

    return '$query événements mode culture créateurs international';
  }

  Map<String, dynamic> _combineSearchResults(
    List<Map<String, dynamic>> results,
    String searchType,
  ) {
    final allResults = <Map<String, dynamic>>[];
    final sources = <String>[];

    for (final result in results) {
      if (result['success'] == true && result['results'] != null) {
        final resultList = result['results'] as List<dynamic>;
        allResults.addAll(resultList.cast<Map<String, dynamic>>());
        sources.add(result['type'] ?? 'unknown');
      }
    }

    // Trier par pertinence
    allResults.sort(
      (a, b) =>
          (b['relevance'] as int? ?? 0).compareTo(a['relevance'] as int? ?? 0),
    );

    // Éliminer les doublons
    final uniqueResults = _removeDuplicates(allResults);

    // Limiter les résultats selon le type
    final maxResults = _getMaxResults(searchType);
    final limitedResults = uniqueResults.take(maxResults).toList();

    return {
      'success': true,
      'results': limitedResults,
      'type': searchType,
      'sources': sources,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'total_results': limitedResults.length,
    };
  }

  List<Map<String, dynamic>> _removeDuplicates(
    List<Map<String, dynamic>> results,
  ) {
    final seen = <String>{};
    final uniqueResults = <Map<String, dynamic>>[];

    for (final result in results) {
      final title = result['title'] ?? '';
      final link = result['link'] ?? '';

      final key = '$title|$link';
      if (!seen.contains(key) && title.isNotEmpty) {
        seen.add(key);
        uniqueResults.add(result);
      }
    }

    return uniqueResults;
  }

  int _getMaxResults(String searchType) {
    switch (searchType) {
      case 'news':
        return 8;
      case 'events':
        return 6;
      case 'shopping':
        return 6;
      case 'weather':
        return 3;
      case 'comprehensive':
        return 12;
      default:
        return 8;
    }
  }

  int _calculateRelevance(String title, String snippet) {
    int score = 0;
    final content = '${title.toLowerCase()} ${snippet.toLowerCase()}';

    // Mots-clés prioritaires
    final priorityKeywords = [
      'mode',
      'fashion',
      'style',
      'tendance',
      'créateur',
      'designer',
      'couture',
      'textile',
      'artisanat',
      'culture',
    ];

    // Mots-clés secondaires
    final secondaryKeywords = [
      'vêtement',
      'tissu',
      'textile',
      'couture',
      'design',
      'culture',
      'tradition',
      'moderne',
      'contemporain',
    ];

    for (final keyword in priorityKeywords) {
      if (content.contains(keyword)) {
        score += 3;
      }
    }

    for (final keyword in secondaryKeywords) {
      if (content.contains(keyword)) {
        score += 1;
      }
    }

    // Bonus pour les sites prioritaires
    for (final site in _prioritySites) {
      if (content.contains(site)) {
        score += 2;
      }
    }

    return score;
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }

  String _extractPrice(String text) {
    final priceRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:€|USD|CFA|FCFA|\$)');
    final match = priceRegex.firstMatch(text);

    if (match != null) {
      return match.group(0) ?? '';
    }

    return '';
  }

  String _cleanSnippet(String snippet) {
    // Nettoyer les caractères indésirables
    return snippet
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(r'[^\w\s\-.,!?;:()àâäéèêëïîôùûüÿçÀÂÄÉÈÊËÏÎÔÙÛÜŸÇ]'),
          '',
        )
        .trim();
  }

  bool _isInCache(String key) {
    if (!_cache.containsKey(key)) return false;

    final cached = _cache[key]!;
    final timestamp = cached['timestamp'] as int? ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return (now - timestamp) < _cacheExpiration;
  }

  void clearCache() {
    _cache.clear();
  }

  Map<String, dynamic> getCacheStats() {
    return {
      'total_entries': _cache.length,
      'cache_expiration': _cacheExpiration,
      'cache_keys': _cache.keys.toList(),
    };
  }
}
