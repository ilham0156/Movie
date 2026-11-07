import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ===========================================================================
// GANTI DENGAN API KEY TMDB KAMU
// ===========================================================================
const String apiKey = 'ISI_API_KEY_KAMU';

void main() => runApp(const MovieApp());

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie App',
      theme: ThemeData.dark(useMaterial3: true)
          .copyWith(scaffoldBackgroundColor: const Color(0xFF121212)),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------
const Map<int, String> genreMap = {
  28: 'Action',
  12: 'Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  14: 'Fantasy',
  36: 'History',
  27: 'Horror',
  10402: 'Music',
  9648: 'Mystery',
  10749: 'Romance',
  878: 'Sci-Fi',
  10770: 'TV Movie',
  53: 'Thriller',
  10752: 'War',
  37: 'Western',
};

class Movie {
  final String title;
  final String year;
  final String genre;
  final String overview;
  final String poster;

  const Movie({
    required this.title,
    required this.year,
    required this.genre,
    required this.overview,
    required this.poster,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final date = (json['release_date'] ?? '') as String;
    final genreIds = (json['genre_ids'] as List?) ?? [];
    return Movie(
      title: (json['title'] ?? 'Unknown') as String,
      year: date.length >= 4 ? date.substring(0, 4) : '-',
      genre: genreIds.isNotEmpty ? (genreMap[genreIds.first] ?? '-') : '-',
      overview: (json['overview'] ?? '') as String,
      poster: 'https://image.tmdb.org/t/p/w500${json['poster_path']}',
    );
  }
}

// ---------------------------------------------------------------------------
// SERVICE
// ---------------------------------------------------------------------------
class TmdbService {
  static const String _base = 'https://api.themoviedb.org/3';

  static Future<List<Movie>> fetch(String path) async {
    final uri = Uri.parse('$_base$path?api_key=$apiKey&language=en-US');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat data (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['results'] as List).cast<Map<String, dynamic>>();
    return results
        .where((m) => m['poster_path'] != null)
        .map(Movie.fromJson)
        .toList();
  }

  static Future<List<Movie>> nowPlaying() => fetch('/movie/now_playing');
  static Future<List<Movie>> trending() => fetch('/trending/movie/day');
  static Future<List<Movie>> popular() => fetch('/movie/popular');
  static Future<List<Movie>> topRated() => fetch('/movie/top_rated');
}

// ---------------------------------------------------------------------------
// HOME PAGE
// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;
  List<Movie> _nowPlaying = [];
  List<Movie> _trending = [];
  List<Movie> _popular = [];
  List<Movie> _topRated = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        TmdbService.nowPlaying(),
        TmdbService.trending(),
        TmdbService.popular(),
        TmdbService.topRated(),
      ]);
      if (!mounted) return;
      setState(() {
        _nowPlaying = results[0].take(8).toList();
        _trending = results[1];
        _popular = results[2];
        _topRated = results[3];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header "Now Playing"
            Container(
              height: 48,
              width: double.infinity,
              alignment: Alignment.center,
              color: const Color(0xFF1C1C1C),
              child: const Text(
                'Now Playing',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            ElevatedButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        children: [
          NowPlayingCarousel(movies: _nowPlaying),
          const SizedBox(height: 12),
          MovieSection(title: 'Trending', movies: _trending),
          MovieSection(title: 'Popular', movies: _popular),
          MovieSection(title: 'Top Rated', movies: _topRated),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOW PLAYING CAROUSEL
// ---------------------------------------------------------------------------
class NowPlayingCarousel extends StatelessWidget {
  final List<Movie> movies;
  const NowPlayingCarousel({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: movies.length,
      options: CarouselOptions(
        height: 260,
        viewportFraction: 0.78,
        enlargeCenterPage: true,
        enlargeFactor: 0.2,
        enableInfiniteScroll: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
      ),
      itemBuilder: (context, index, realIndex) {
        return NowPlayingCard(movie: movies[index]);
      },
    );
  }
}

class NowPlayingCard extends StatelessWidget {
  final Movie movie;
  const NowPlayingCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            movie.poster,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade800,
              child: const Icon(Icons.movie, size: 48),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${movie.year}   ${movie.genre}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.overview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SECTION (Trending / Popular / Top Rated)
// ---------------------------------------------------------------------------
class MovieSection extends StatelessWidget {
  final String title;
  final List<Movie> movies;

  const MovieSection({super.key, required this.title, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'More',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: movies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return PosterCard(movie: movies[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PosterCard extends StatelessWidget {
  final Movie movie;
  const PosterCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          movie.poster,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade800,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4),
            child: Text(
              movie.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }
}
