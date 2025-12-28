import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/datasources/hospitals_remote_data_source.dart';
import '../../../auth/data/datasources/specialities_remote_data_source.dart';
import '../../../auth/domain/entities/hospital.dart';
import '../../../auth/domain/entities/speciality.dart';

class ProfessionalInformationPage extends StatefulWidget {
  final String userType;
  final String? adminSubtype;

  const ProfessionalInformationPage({
    super.key,
    required this.userType,
    this.adminSubtype,
  });

  @override
  State<ProfessionalInformationPage> createState() =>
      _ProfessionalInformationPageState();
}

class _ProfessionalInformationPageState
    extends State<ProfessionalInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  Speciality? _selectedSpeciality;
  Hospital? _selectedHospital;
  List<Hospital> _hospitals = [];
  List<Speciality> _specialities = [];
  bool _isLoadingHospitals = false;
  bool _isLoadingSpecialities = false;
  String? _hospitalsError;
  String? _specialitiesError;

  final HospitalsRemoteDataSource _hospitalsDataSource =
      HospitalsRemoteDataSourceImpl(DioClient());
  final SpecialitiesRemoteDataSource _specialitiesDataSource =
      SpecialitiesRemoteDataSourceImpl(DioClient());

  @override
  void initState() {
    super.initState();
    if (_needsHospitalId() || _isAdministrative()) {
      _loadHospitals();
    }
    if (_needsSpecialty()) {
      _loadSpecialities();
    }
  }

  Future<void> _loadSpecialities() async {
    setState(() {
      _isLoadingSpecialities = true;
      _specialitiesError = null;
    });

    try {
      final specialities = await _specialitiesDataSource.getSpecialities();
      setState(() {
        _specialities = specialities;
        _isLoadingSpecialities = false;
      });
    } catch (e) {
      setState(() {
        _specialitiesError = e.toString();
        _isLoadingSpecialities = false;
      });
    }
  }

  Future<void> _loadHospitals() async {
    setState(() {
      _isLoadingHospitals = true;
      _hospitalsError = null;
    });

    try {
      final hospitals = await _hospitalsDataSource.getHospitals();
      setState(() {
        _hospitals = hospitals;
        _isLoadingHospitals = false;
      });
    } catch (e) {
      setState(() {
        _hospitalsError = e.toString();
        _isLoadingHospitals = false;
      });
    }
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      if (_needsHospitalId() && _selectedHospital == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a hospital')),
        );
        return;
      }

      if (_needsSpecialty() && _isSpecialtyMandatory() && _selectedSpeciality == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a specialty')),
        );
        return;
      }

      // Navigate to register page with professional information
      final registerData = <String, dynamic>{
        'user_type': widget.userType,
      };

      if (_isAdministrative() && widget.adminSubtype != null) {
        registerData['admin_subtype'] = widget.adminSubtype!;
      }

      if (_licenseController.text.trim().isNotEmpty) {
        registerData['licence_number'] = _licenseController.text.trim();
      }

      if (_selectedSpeciality != null) {
        registerData['speciality'] = _selectedSpeciality!.name;
      }

      if (_selectedHospital != null) {
        registerData['hospital_id'] = _selectedHospital!.id;
      }

      context.go('/register', extra: registerData);
    }
  }

  String _getUserTypeLabel() {
    if (_isAdministrative()) {
      if (widget.adminSubtype == 'hospital_admin') {
        return 'Hospital Admin';
      } else if (widget.adminSubtype == 'physician_admin') {
        return 'Physician Admin';
      }
      return 'Administrative';
    }
    switch (widget.userType) {
      case 'physician':
        return 'Physician';
      case 'resident':
        return 'Resident';
      case 'intern':
        return 'Intern';
      default:
        return 'Professional';
    }
  }

  bool _isAdministrative() {
    return widget.userType == 'administrative';
  }

  bool _needsLicense() {
    // Physician: mandatory, Resident: optional, Intern: no
    // Administrative Physician Admin: mandatory
    if (_isAdministrative()) {
      return widget.adminSubtype == 'physician_admin';
    }
    return widget.userType == 'physician' || widget.userType == 'resident';
  }

  bool _isLicenseMandatory() {
    // Mandatory for Physician and Administrative Physician Admin
    if (_isAdministrative()) {
      return widget.adminSubtype == 'physician_admin';
    }
    return widget.userType == 'physician';
  }

  bool _needsSpecialty() {
    // Physician: mandatory, Resident: optional, Intern: no
    // Administrative Physician Admin: mandatory
    if (_isAdministrative()) {
      return widget.adminSubtype == 'physician_admin';
    }
    return widget.userType == 'physician' || widget.userType == 'resident';
  }

  bool _isSpecialtyMandatory() {
    // Mandatory for Physician and Administrative Physician Admin
    if (_isAdministrative()) {
      return widget.adminSubtype == 'physician_admin';
    }
    return widget.userType == 'physician';
  }

  bool _needsHospitalId() {
    // Intern: mandatory
    // Administrative Hospital Admin: mandatory
    if (_isAdministrative()) {
      return widget.adminSubtype == 'hospital_admin';
    }
    return widget.userType == 'intern';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseTextColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final cardFill = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo
            Image.asset(
              'assets/icons/logo.png',
              width: 100,
              height: 100,
              color: isDark ? Colors.white : null,
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              'Professional Information',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: baseTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Please provide your ${_getUserTypeLabel().toLowerCase()} details',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // License Number (for Physician and Resident)
                      if (_needsLicense()) ...[
                        Text(
                          'License Number${_isLicenseMandatory() ? ' *' : ' (Optional)'}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: baseTextColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _licenseController,
                          validator: _isLicenseMandatory()
                              ? (value) => Validators.required(
                                    value,
                                    fieldName: 'License Number',
                                  )
                              : null,
                          decoration: InputDecoration(
                            hintText: 'MD-2025-12345',
                            hintStyle: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              color: const Color(0xFF30BEC6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF30BEC6),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            filled: true,
                            fillColor: cardFill,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Specialty Dropdown (for Physician, Resident, and Administrative Physician Admin)
                      if (_needsSpecialty()) ...[
                        Text(
                          'Specialty${_isSpecialtyMandatory() ? ' *' : ' (Optional)'}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: baseTextColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_isLoadingSpecialities)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_specialitiesError != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Failed to load specialities',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadSpecialities,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: cardFill,
                              border: Border.all(
                                color: _selectedSpeciality != null
                                    ? const Color(0xFF30BEC6)
                                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                width: _selectedSpeciality != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<Speciality>(
                              value: _selectedSpeciality,
                              decoration: InputDecoration(
                                hintText: 'Select Specialty',
                                hintStyle: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                                prefixIcon: Icon(
                                  Icons.medical_services_outlined,
                                  color: const Color(0xFF30BEC6),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: cardFill,
                              ),
                              items: _specialities.map((speciality) {
                                return DropdownMenuItem<Speciality>(
                                  value: speciality,
                                  child: Text(speciality.name),
                                );
                              }).toList(),
                              onChanged: (Speciality? value) {
                                setState(() {
                                  _selectedSpeciality = value;
                                });
                              },
                              validator: _isSpecialtyMandatory()
                                  ? (value) {
                                      if (value == null) {
                                        return 'Please select a specialty';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                      // Hospital Dropdown (for Intern and Administrative Hospital Admin)
                      if (_needsHospitalId()) ...[
                        Text(
                          'Hospital *',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: baseTextColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_isLoadingHospitals)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_hospitalsError != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Failed to load hospitals',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadHospitals,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: cardFill,
                              border: Border.all(
                                color: _selectedHospital != null
                                    ? const Color(0xFF30BEC6)
                                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                width: _selectedHospital != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<Hospital>(
                              value: _selectedHospital,
                              decoration: InputDecoration(
                                hintText: 'Select Hospital',
                                hintStyle: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                                prefixIcon: Icon(
                                  Icons.local_hospital_outlined,
                                  color: const Color(0xFF30BEC6),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: cardFill,
                              ),
                              items: _hospitals.map((hospital) {
                                return DropdownMenuItem<Hospital>(
                                  value: hospital,
                                  child: Text(hospital.name),
                                );
                              }).toList(),
                              onChanged: (Hospital? value) {
                                setState(() {
                                  _selectedHospital = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a hospital';
                                }
                                return null;
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                      // Next Button
                      Container(
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
                          onPressed: _handleNext,
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
