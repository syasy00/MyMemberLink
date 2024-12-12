import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_member_link/myconfig.dart';
import 'package:http/http.dart' as http;
import 'package:my_member_link/models/news.dart';

import 'package:my_member_link/components/bottom_bar.dart';
import 'new_news.dart';
import 'main_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = "";
  List<News> allNews = [];
  List<News> filteredNews = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllNews();
  }

  Future<void> _loadAllNews() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
            "${MyConfig.servername}/memberlink/api/load_news.php?no_limit=true"),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == "success" && data['data'] != null) {
          List<News> results = (data['data']['news'] as List).map((item) {
            return News.fromJson(item);
          }).toList();

          setState(() {
            allNews = results;
            filteredNews = results;
          });
        } else {
          setState(() {
            allNews = [];
            filteredNews = [];
          });
        }
      } else {
        debugPrint("API Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error loading news: $e");
      setState(() {
        allNews = [];
        filteredNews = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterNews(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredNews = allNews;
      } else {
        filteredNews = allNews
            .where((news) =>
                (news.newsTitle ?? "")
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                (news.newsDetails ?? "")
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Search News",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredNews.isEmpty
                      ? const Center(
                          child: Text(
                            "No results found.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6C757D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : _buildNewsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 1, // Search tab selected
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const NewNewsScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 230, 230, 230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: _filterNews,
        decoration: InputDecoration(
          hintText: 'Search news...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6C757D)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    return ListView.builder(
      itemCount: filteredNews.length,
      itemBuilder: (context, index) {
        final news = filteredNews[index];
        return Card(
          color: const Color.fromARGB(255, 239, 243, 247),
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(Icons.article, color: Colors.blue, size: 40),
            title: Text(
              news.newsTitle ?? "Untitled News",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212529),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                news.newsDetails ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                ),
              ),
            ),
            onTap: () {
              _showNewsDetailDialog(news); // Show dialog for details
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
          backgroundColor: const Color.fromARGB(255, 239, 243, 247),
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
}
