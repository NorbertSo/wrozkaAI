// lib/screens/user_data_screen.dart
// Zaktualizowany ekran danych użytkownika z nowymi polami

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import '../services/user_preferences_service.dart';
import '../utils/constants.dart';

class UserDataScreen extends StatefulWidget {
  final UserData userData;
  final void Function(UserData?)? onUserDataChanged;

  const UserDataScreen({
    super.key,
    required this.userData,
    this.onUserDataChanged,
  });

  @override
  State<UserDataScreen> createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen> {
  late TextEditingController _nameController;
  late TextEditingController _birthPlaceController;
  late DateTime _birthDate;
  TimeOfDay? _birthTime;
  late String _gender;
  late String _dominantHand;
  bool _rememberBirthTime = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData.name);
    _birthPlaceController =
        TextEditingController(text: widget.userData.birthPlace ?? '');
    _birthDate = widget.userData.birthDate;
    _gender = widget.userData.gender;
    _dominantHand = widget.userData.dominantHand;

    // Parse birthTime jeśli istnieje
    if (widget.userData.birthTime != null) {
      final timeParts = widget.userData.birthTime!.split(':');
      if (timeParts.length == 2) {
        _birthTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    } else {
      _rememberBirthTime = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.cyan,
              onPrimary: Colors.white,
              surface: const Color(0xFF1A2332),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickBirthTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.cyan,
                onPrimary: Colors.white,
                surface: const Color(0xFF1A2332),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _birthTime = picked);
    }
  }

  void _saveUserData() async {
    try {
      String? birthTimeString;
      if (_rememberBirthTime && _birthTime != null) {
        birthTimeString =
            '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}';
      }

      String? birthPlace;
      if (_birthPlaceController.text.trim().isNotEmpty) {
        birthPlace = _birthPlaceController.text.trim();
      }

      final newUser = UserData(
        name: _nameController.text.trim(),
        birthDate: _birthDate,
        birthTime: birthTimeString,
        birthPlace: birthPlace,
        gender: _gender,
        dominantHand: _dominantHand,
        registrationDate: widget.userData.registrationDate,
      );

      await UserPreferencesService.saveUserData(newUser);
      widget.onUserDataChanged?.call(newUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dane zostały zaktualizowane',
              style: GoogleFonts.cinzelDecorative(),
            ),
            backgroundColor: Colors.green.withOpacity(0.8),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Błąd zapisywania: $e',
              style: GoogleFonts.cinzelDecorative(),
            ),
            backgroundColor: Colors.red.withOpacity(0.8),
          ),
        );
      }
    }
  }

  void _deleteUserData() async {
    try {
      await UserPreferencesService.clearAllUserData();
      widget.onUserDataChanged?.call(null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dane zostały usunięte',
              style: GoogleFonts.cinzelDecorative(),
            ),
            backgroundColor: Colors.orange.withOpacity(0.8),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Błąd usuwania: $e',
              style: GoogleFonts.cinzelDecorative(),
            ),
            backgroundColor: Colors.red.withOpacity(0.8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        title: Text(
          'Moje dane',
          style: GoogleFonts.cinzelDecorative(
            color: AppColors.cyan,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.welcomeGradient,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header z informacjami
              _buildInfoHeader(),
              const SizedBox(height: 32),

              // Formularz edycji
              _buildEditForm(),

              const SizedBox(height: 40),

              // Przycisk zapisz
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withOpacity(0.2),
            AppColors.cyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.cyan, size: 24),
              const SizedBox(width: 12),
              Text(
                'Aktualne dane',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Imię', widget.userData.name),
          _buildInfoRow('Wiek', '${widget.userData.age} lat'),
          _buildInfoRow('Znak zodiaku', widget.userData.zodiacSign),
          _buildInfoRow('Data urodzenia',
              '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}'),
          _buildInfoRow(
              'Godzina urodzenia', widget.userData.formattedBirthTime),
          _buildInfoRow(
              'Miejsce urodzenia', widget.userData.formattedBirthPlace),
          _buildInfoRow('Płeć', _getGenderDisplayName(_gender)),
          _buildInfoRow(
              'Dominująca ręka', _dominantHand == 'left' ? 'Lewa' : 'Prawa'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edytuj dane',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Imię
          _buildTextField('Imię', _nameController),
          const SizedBox(height: 16),

          // Data urodzenia
          _buildDatePicker(),
          const SizedBox(height: 16),

          // Godzina urodzenia
          _buildTimePicker(),
          const SizedBox(height: 16),

          // Miejsce urodzenia
          _buildTextField(
              'Miejsce urodzenia (opcjonalne)', _birthPlaceController),
          const SizedBox(height: 16),

          // Płeć
          _buildGenderDropdown(),
          const SizedBox(height: 16),

          // Dominująca ręka
          _buildHandDropdown(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cinzelDecorative(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.cyan.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.cyan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data urodzenia',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickBirthDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
                    style: GoogleFonts.cinzelDecorative(color: Colors.white),
                  ),
                ),
                Icon(Icons.calendar_today, color: AppColors.cyan, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Godzina urodzenia',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _rememberBirthTime ? _pickBirthTime : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: _rememberBirthTime
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              border: Border.all(
                color: _rememberBirthTime
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _birthTime != null
                        ? '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}'
                        : _rememberBirthTime
                            ? 'Wybierz godzinę'
                            : 'Godzina nieznana',
                    style: GoogleFonts.cinzelDecorative(
                      color: _rememberBirthTime ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
                Icon(
                  Icons.access_time,
                  color: _rememberBirthTime ? AppColors.cyan : Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: !_rememberBirthTime,
              onChanged: (value) {
                setState(() {
                  _rememberBirthTime = !(value ?? false);
                  if (!_rememberBirthTime) {
                    _birthTime = null;
                  }
                });
              },
              activeColor: AppColors.cyan,
            ),
            Text(
              'Nie pamiętam godziny urodzenia',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Płeć',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          dropdownColor: AppColors.deepBlue,
          style: GoogleFonts.cinzelDecorative(color: Colors.white),
          items: const [
            DropdownMenuItem(value: 'female', child: Text('Kobieta')),
            DropdownMenuItem(value: 'male', child: Text('Mężczyzna')),
            DropdownMenuItem(value: 'other', child: Text('Inna')),
          ],
          onChanged: (v) => setState(() => _gender = v ?? 'other'),
        ),
      ],
    );
  }

  Widget _buildHandDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dominująca ręka',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _dominantHand,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          dropdownColor: AppColors.deepBlue,
          style: GoogleFonts.cinzelDecorative(color: Colors.white),
          items: const [
            DropdownMenuItem(value: 'right', child: Text('Prawa')),
            DropdownMenuItem(value: 'left', child: Text('Lewa')),
          ],
          onChanged: (v) => setState(() => _dominantHand = v ?? 'right'),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveUserData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Zapisz zmiany',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _getGenderDisplayName(String gender) {
    switch (gender) {
      case 'female':
        return 'Kobieta';
      case 'male':
        return 'Mężczyzna';
      default:
        return 'Inna';
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepBlue,
        title: Text(
          'Usuń wszystkie dane',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Czy na pewno chcesz usunąć wszystkie swoje dane? Ta operacja nie może zostać cofnięta.',
          style: GoogleFonts.cinzelDecorative(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anuluj',
              style: GoogleFonts.cinzelDecorative(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteUserData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Usuń',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
