import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserTypeSelectionPage extends StatefulWidget {
  const UserTypeSelectionPage({super.key});

  @override
  State<UserTypeSelectionPage> createState() => _UserTypeSelectionPageState();
}

class _UserTypeSelectionPageState extends State<UserTypeSelectionPage> {
  String? _selectedUserType;

  void _handleNext() {
    if (_selectedUserType != null) {
      if (_selectedUserType == 'administrative') {
        // Go to admin subtype selection first
        context.go('/admin-subtype-selection');
      } else if (_selectedUserType == 'physician' ||
          _selectedUserType == 'resident' ||
          _selectedUserType == 'intern') {
        // Go to professional information page for medical professionals
        context.go('/professional-information', extra: {
          'user_type': _selectedUserType,
        });
      } else {
        // Go directly to register page for other types
        context.go('/register', extra: {'user_type': _selectedUserType});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo
            Image.asset(
              'assets/icons/logo.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 32),
            // Title
            const Text(
              'Select User Type',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Choose The Option That Best Describes Your Role',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // User Type Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _buildUserTypeCard(
                      'Physician',
                      'assets/icons/phyisician.png',
                      'physician',
                    ),
                    _buildUserTypeCard(
                      'Resident',
                      'assets/icons/Resident.png',
                      'resident',
                    ),
                    _buildUserTypeCard(
                      'Intern',
                      'assets/icons/intern.png',
                      'intern',
                    ),
                    _buildUserTypeCard(
                      'Administrative',
                      'assets/icons/administrarive.png',
                      'administrative',
                    ),
                  ],
                ),
              ),
            ),
            // Next Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF30BEC6),
                      const Color(0xFF0891A3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _selectedUserType != null ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(String title, String iconPath, String value) {
    final isSelected = _selectedUserType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = value;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF30BEC6)
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF30BEC6).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person,
                  size: 80,
                  color: isSelected
                      ? const Color(0xFF30BEC6)
                      : Colors.grey.shade400,
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF30BEC6)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
