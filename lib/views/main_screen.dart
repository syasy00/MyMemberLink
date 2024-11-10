import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:my_member_link/models/news.dart';
import 'package:my_member_link/myconfig.dart';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<News> newsList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: newsList.isEmpty
          ? const Center(
              child: Text("Loading..."),
            )
          : ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(newsList[index].newsTitle.toString()),
                    subtitle: Text(newsList[index].newsDetails.toString()),
                  ),
                );
              }),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              onTap: () {},
              title: const Text("Newsletter"),
            ),
            const ListTile(
              title: Text("Events"),
            ),
            const ListTile(
              title: Text("Members"),
            ),
            const ListTile(
              title: Text("Vetting"),
            ),
            const ListTile(
              title: Text("Members"),
            ),
            const ListTile(
              title: Text("Payment"),
            ),
            const ListTile(
              title: Text("Product"),
            )
          ],
        ),
      ),
    );
  }
}
