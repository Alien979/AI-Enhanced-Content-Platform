import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'help_support_screen.dart';
import '../services/user_service.dart';
import '../services/book_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final BookService _bookService = BookService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late Future<Map<String, dynamic>> _userDataFuture;
  late Future<Map<String, dynamic>> _userStatsFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _userService.getUserData();
    _userStatsFuture = _bookService.getUserBookStats(_auth.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _navigateToEditProfile(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _userDataFuture = _userService.getUserData();
            _userStatsFuture = _bookService.getUserBookStats(_auth.currentUser!.uid);
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: Future.wait([_userDataFuture, _userStatsFuture]).then((results) {
              return {...results[0], ...results[1]};
            }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No user data found'));
              }

              final userData = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(userData),
                  _buildUserStats(userData),
                  _buildReadingProgress(userData),
                  _buildRecentActivity(userData),
                  _buildAccountOptions(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: userData['photoURL'] != null
                ? CachedNetworkImageProvider(userData['photoURL'])
                : null,
            child: userData['photoURL'] == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['displayName'] ?? 'Anonymous Writer',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  userData['email'] ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  userData['bio'] ?? 'No bio available',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Stats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Books Written', userData['booksWritten'] ?? 0),
              _buildStatItem('Words Written', userData['totalWordsWritten'] ?? 0),
              _buildStatItem('Books Read', userData['booksRead'] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildReadingProgress(Map<String, dynamic> userData) {
    final readingProgress = userData['readingProgress'] as Map<String, dynamic>? ?? {};
    final spots = readingProgress.entries
        .map((e) => FlSpot(double.parse(e.key), e.value.toDouble()))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reading Progress',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: spots.isNotEmpty ? spots.first.x : 0,
                maxX: spots.isNotEmpty ? spots.last.x : 6,
                minY: 0,
                maxY: spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic> userData) {
    final recentActivity = userData['recentActivity'] as List<dynamic>? ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentActivity.length,
            itemBuilder: (context, index) {
              final activity = recentActivity[index];
              return _buildActivityItem(activity['action'], activity['timestamp']);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String activity, Timestamp time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, size: 12, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            _formatTimestamp(time),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAccountOption('Edit Profile', Icons.edit, _navigateToEditProfile),
          _buildAccountOption('Notification Settings', Icons.notifications, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
            );
          }),
          _buildAccountOption('Privacy Settings', Icons.lock, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
            );
          }),
          _buildAccountOption('Help & Support', Icons.help, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
            );
          }),
          _buildAccountOption('Log Out', Icons.exit_to_app, _signOut),
        ],
      ),
    );
  }

  Widget _buildAccountOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    if (result == true) {
      setState(() {
        _userDataFuture = _userService.getUserData();
      });
    }
  }

  void _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}