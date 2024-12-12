import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_member_link/models/news.dart';
import 'package:my_member_link/myconfig.dart';
import 'package:http/http.dart' as http;
import 'new_news.dart';
import '../mydrawer.dart';
import 'search_screen.dart';
import 'package:my_member_link/components/bottom_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<News> newsList = [];
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = false;

  String username = "User";
  String sortOrder = "Latest";
  String searchQuery = ""; // To hold the search input
  int _selectedIndex = 0; // Track the active tab in the bottom bar

  late PageController _pageController;
  int _currentPageIndex = 0;
  late Timer _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadNewsData();

    _pageController = PageController();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients && newsList.isNotEmpty) {
        int nextPage = (_currentPageIndex + 1) % newsList.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPageIndex = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoSlideTimer.cancel();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? "User";
    });
  }

  Future<void> _loadNewsData({int page = 1}) async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
            "${MyConfig.servername}/memberlink/api/load_news.php?pageno=$page&sort=$sortOrder&query=$searchQuery"),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == "success") {
          final prefs = await SharedPreferences.getInstance();
          List<String> likedNews = prefs.getStringList('liked_news') ?? [];

          List<News> fetchedNews = (data['data']['news'] as List).map((item) {
            final news = News.fromJson(item);
            news.likedByUser = likedNews.contains(news.newsId);
            return news;
          }).toList();

          setState(() {
            currentPage = page;
            totalPages = data['data']['total_pages'] ?? 1;
            newsList = fetchedNews;
          });
        }
      } else {
        log("Error: ${response.statusCode}");
      }
    } catch (e) {
      log("Exception: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleLike(News news) async {
    final action = news.likedByUser ? 'unlike' : 'like';
    final url = "${MyConfig.servername}/memberlink/api/like_news.php";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'news_id': news.newsId, 'action': action}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        List<String> likedNews = prefs.getStringList('liked_news') ?? [];

        setState(() {
          news.likedByUser = !news.likedByUser;
          news.likes += news.likedByUser ? 1 : -1;

          if (news.likedByUser) {
            likedNews.add(news.newsId!);
          } else {
            likedNews.remove(news.newsId);
          }
          prefs.setStringList('liked_news', likedNews);
        });
      } else {
        log("Failed to update like status");
      }
    } catch (e) {
      log("Error: $e");
    }
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Search News",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value; // Update search query
                    _loadNewsData(page: 1); // Trigger search
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Enter keywords...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Bulletin News",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer:MyDrawer(activePage: "Home"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadNewsData(page: 1);
              },
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSortOptions(),
                  const SizedBox(height: 20),
                  _buildFeaturedNews(),
                  const SizedBox(height: 20),
                  _buildNewsList(),
                  const SizedBox(height: 20),
                  _buildStylishPagination(),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewNewsScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildCustomBarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE7F3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2D9CDB)
                  : const Color(0xFFB0BEC5),
              size: 24,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF2D9CDB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          "Welcome back, $username",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSortOption("Latest", isSelected: sortOrder == "Latest"),
        _buildSortOption("Trending", isSelected: sortOrder == "Trending"),
      ],
    );
  }

  Widget _buildSortOption(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          sortOrder = label; // Update the sort order
          _loadNewsData(page: 1); // Reload data based on the selected tab
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          if (isSelected)
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ),
    );
  }
Widget _buildFeaturedNews() {
  if (newsList.isEmpty) {
    return const Center(child: Text("No Featured News Available"));
  }

  return Column(
    children: [
      SizedBox(
        height: 220,
        child: PageView.builder(
          controller: _pageController,
          itemCount: newsList.length,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final news = newsList[index];
            return GestureDetector(
              onTap: () {
                _showNewsDetailDialog(news); // Display details in a dialog
              },
              child: Card(
                color: const Color.fromARGB(255, 239, 243, 247),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/news2.jpg', // Replace with a dynamic image if available
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        news.newsTitle ?? "Default Title",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      // Page indicators
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(newsList.length, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPageIndex == index ? Colors.blue : Colors.grey,
            ),
          );
        }),
      ),
    ],
  );
}



  Widget _buildNewsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final news = newsList[index];
        return Card(
          color: const Color.fromARGB(255, 239, 243, 247),
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.article, color: Colors.blue, size: 40),
            title: Text(
              news.newsTitle ?? "Default Title",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  truncateString(
                      news.newsDetails ?? "No details available", 80),
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 8),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                news.likedByUser ? Icons.favorite : Icons.favorite_border,
                color: news.likedByUser ? Colors.red : Colors.grey,
              ),
              onPressed: () async {
                await toggleLike(news);
              },
            ),
            onTap: () {
              _showNewsDetailDialog(news);
            },
          ),
        );
      },
    );
  }

  void _showNewsDetailDialog(News news) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
         backgroundColor:  const Color.fromARGB(255, 239, 243, 247),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // News Title
                Text(
                  news.newsTitle ?? "Untitled News",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // News Date
                Text(
                  "Published on: ${news.newsDate ?? "Unknown"}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),

                // Animated GIF
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/announcement.gif', // Path to your GIF file
                    width: 200,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),

                // News Details
                Text(
                  news.newsDetails ?? "No details available.",
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 20),

                // Likes Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: news.likedByUser ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "${news.likes} ${news.likes == 1 ? "like" : "likes"}",
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Buttons Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Close Button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 197, 197, 197),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Close",
                          style: TextStyle(color: Colors.white)),
                    ),

                    // Edit Button
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 142, 188, 226),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Edit",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStylishPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left,
              color: currentPage > 1 ? Colors.blue : Colors.grey),
          onPressed: currentPage > 1
              ? () => _loadNewsData(page: currentPage - 1)
              : null,
        ),
        ...List.generate(
          totalPages,
          (index) {
            final pageNumber = index + 1;
            return GestureDetector(
              onTap: () => _loadNewsData(page: pageNumber),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pageNumber == currentPage
                      ? Colors.blue
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pageNumber.toString(),
                  style: TextStyle(
                    color:
                        pageNumber == currentPage ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.chevron_right,
              color: currentPage < totalPages ? Colors.blue : Colors.grey),
          onPressed: currentPage < totalPages
              ? () => _loadNewsData(page: currentPage + 1)
              : null,
        ),
      ],
    );
  }

  String truncateString(String str, int length) {
    return str.length > length ? "${str.substring(0, length)}..." : str;
  }
}
