import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'My Books',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/home'); // Navigate to Home
            break;
          case 1:
            Navigator.pushNamed(context, '/myBooks'); // Navigate to My Books
            break;
          case 2:
            Navigator.pushNamed(context, '/create'); // Navigate to Create
            break;
          case 3:
            Navigator.pushNamed(context, '/profile'); // Navigate to Profile
            break;
          case 4:
            Navigator.pushNamed(context, '/more'); // Navigate to More
            break;
          default:
            break;
        }
      },
    );
  }
}
