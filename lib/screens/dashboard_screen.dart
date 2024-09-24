import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/quote_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define a color scheme
  final Color primaryColor = const Color(0xFF6200EE);
  final Color secondaryColor = const Color(0xFF03DAC6);
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color textColor = const Color(0xFF333333);

  String _currentQuote = 'Loading...';
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();
    _loadQuote();
    // Set up a timer to refresh the quote every hour
    _quoteTimer = Timer.periodic(const Duration(hours: 1), (Timer t) => _loadQuote());
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

Future<void> _loadQuote() async {
  String quote = await QuoteService.getOrGenerateQuote();
  if (mounted) {
    setState(() {
      _currentQuote = quote;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/ai_settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadQuote();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              _buildQuickStats(),
              _buildWritingStreak(),
              _buildRecentBooks(context),
              _buildMotivationalQuote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(_auth.currentUser!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Card(
            color: secondaryColor,
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.person_add, color: Colors.white),
              title: const Text('Welcome! Please complete your profile.', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => Navigator.pushNamed(context, '/user_profile'),
            ),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String userName = userData['displayName'] ?? 'Writer';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              Text(
                userName,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ready to write today?',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('books')
          .where('authorId', isEqualTo: _auth.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)));
        }

        int totalBooks = snapshot.data?.docs.length ?? 0;
        int booksInProgress = snapshot.data?.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['isPublished'] == false;
        }).length ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total Books', totalBooks.toString(), Icons.book, primaryColor),
              _buildStatCard('In Progress', booksInProgress.toString(), Icons.edit, secondaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.8))),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWritingStreak() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: const Icon(Icons.local_fire_department, color: Colors.orange),
          title: Text('Writing Streak', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          subtitle: Text('5 days in a row!', style: TextStyle(color: textColor.withOpacity(0.8))),
          trailing: Icon(Icons.chevron_right, color: primaryColor),
          onTap: () {
            // Navigate to writing streak details
          },
        ),
      ),
    );
  }

  Widget _buildRecentBooks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Books', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('books')
                .where('authorId', isEqualTo: _auth.currentUser!.uid)
                .orderBy('updatedAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text('No books yet. Start writing!', style: TextStyle(color: textColor.withOpacity(0.8)));
              }

              return SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var book = doc.data() as Map<String, dynamic>;
                    return Hero(
                      tag: 'book-${doc.id}',  // Unique hero tag for each book
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book['title'] ?? 'Untitled',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Last updated: ${_formatDate(book['updatedAt'] as Timestamp?)}',
                                style: TextStyle(color: textColor.withOpacity(0.8)),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/book_writing',
                                  arguments: {'bookId': doc.id},
                                ),
                                child: const Text('Continue Writing'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalQuote() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quote of the Hour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 10),
              Text(
                _currentQuote,
                style: TextStyle(fontStyle: FontStyle.italic, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }
}