import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSubtypeSelectionPage extends StatefulWidget {
  const AdminSubtypeSelectionPage({super.key});

  @override
  State<AdminSubtypeSelectionPage> createState() =>
      _AdminSubtypeSelectionPageState();
}

class _AdminSubtypeSelectionPageState
    extends State<AdminSubtypeSelectionPage> {
  String? _selectedSubType;

  void _handleNext() {
    if (_selectedSubType != null) {
      // Navigate to professional information page with admin subtype
      context.go('/professional-information', extra: {
        'user_type': 'administrative',
        'admin_subtype': _selectedSubType!,
      });
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
              'Administrative Type',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Select Your Administrative Role',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            // Role Selection Cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAdminTypeCard(
                        'Hospital Admin',
                        'assets/icons/hospitaladminlogo.png',
                        'hospital_admin',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAdminTypeCard(
                        'Physician Admin',
                        'assets/icons/physadminlogo.png',
                        'physician_admin',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                  onPressed: _selectedSubType != null ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
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

  Widget _buildAdminTypeCard(String title, String iconPath, String value) {
    final isSelected = _selectedSubType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubType = value;
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
              : [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  value == 'hospital'
                      ? Icons.local_hospital
                      : Icons.medical_services,
                  size: 80,
                  color: isSelected
                      ? const Color(0xFF30BEC6)
                      : Colors.grey.shade400,
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF30BEC6)
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
