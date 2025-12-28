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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Logo
            Image.asset(
              'assets/icons/logo.png',
              width: 88,
              height: 88,
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'Administrative Type',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 6),
            // Subtitle
            Text(
              'Select Your Administrative Role',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
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
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: _selectedSubType != null ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 84,
              height: 84,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  value == 'hospital'
                      ? Icons.local_hospital
                      : Icons.medical_services,
                  size: 64,
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
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
