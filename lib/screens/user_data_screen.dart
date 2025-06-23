// lib/screens/user_data_screen.dart
// KOMPLETNIE NAPRAWIONA WERSJA - Problem z zapisywaniem i wyświetlaniem danych rozwiązany

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import '../services/user_preferences_service.dart';
import '../services/haptic_service.dart';
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

  // ✅ DODANE: Flagi kontroli
  bool _hasUnsavedChanges = false;
  late UserData _originalUserData;

  // ✅ KLUCZOWA POPRAWKA: Aktualne zapisane dane do wyświetlania w podglądzie
  late UserData _currentSavedUserData;

  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();

    // ✅ POPRAWKA: Zapisz oryginalne dane
    _originalUserData = widget.userData;
    _currentSavedUserData = widget.userData; // ✅ DODANE: Dane do podglądu

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

    // ✅ DODANE: Listener do trackowania zmian
    _nameController.addListener(_onDataChanged);
    _birthPlaceController.addListener(_onDataChanged);
  }

  // ✅ POPRAWKA: Lepsze wykrywanie zmian
  void _onDataChanged() {
    bool hasChanges = false;

    if (_nameController.text.trim() != _currentSavedUserData.name)
      hasChanges = true;
    if ((_birthPlaceController.text.trim().isEmpty
            ? null
            : _birthPlaceController.text.trim()) !=
        _currentSavedUserData.birthPlace) hasChanges = true;
    if (_birthDate != _currentSavedUserData.birthDate) hasChanges = true;
    if (_gender != _currentSavedUserData.gender) hasChanges = true;
    if (_dominantHand != _currentSavedUserData.dominantHand) hasChanges = true;

    // Sprawdź zmiany w czasie urodzenia
    String? newBirthTime;
    if (_rememberBirthTime && _birthTime != null) {
      newBirthTime =
          '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}';
    }
    if (newBirthTime != _currentSavedUserData.birthTime) hasChanges = true;

    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
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
      setState(() {
        _birthDate = picked;
      });
      _onDataChanged();
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
      setState(() {
        _birthTime = picked;
      });
      _onDataChanged();
    }
  }

  // ✅ KLUCZOWA POPRAWKA: Lepsze zapisywanie z odświeżaniem podglądu
  void _saveUserData() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    try {
      if (_nameController.text.trim().isEmpty) {
        _showErrorSnackBar('Imię nie może być puste');
        return;
      }

      // Pokazuj loading
      _showLoadingDialog();

      // Mocniejsza wibracja przy zapisie
      await _hapticService.trigger(HapticType.impact);

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
        registrationDate: _originalUserData.registrationDate,
      );

      // ✅ KLUCZOWA POPRAWKA: Wymuś reload SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      // Zapisz nowe dane
      await UserPreferencesService.saveUserData(newUser);

      // Dodatkowy reload po zapisie
      await prefs.reload();

      print('✅ PRZED AKTUALIZACJĄ STANU:');
      print('   - Oryginalne: ${_currentSavedUserData.name}');
      print('   - Nowe: ${newUser.name}');

      // ✅ KLUCZOWA POPRAWKA: Zaktualizuj oba zestawy danych + wymuszenie rebuild
      if (mounted) {
        setState(() {
          _currentSavedUserData = newUser; // ✅ PODGLĄD
          _originalUserData = newUser; // ✅ REFERENCJA
          _hasUnsavedChanges = false;
        });

        // ✅ DODATKOWE WYMUSZENIE REBUILD PO KRÓTKIM OPÓŹNIENIU
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {}); // Wymuszenie dodatkowego rebuild
        }
      }

      print('✅ PO AKTUALIZACJI STANU:');
      print('   - Current saved: ${_currentSavedUserData.name}');
      print('   - Current place: ${_currentSavedUserData.birthPlace}');
      print('   - Has changes: $_hasUnsavedChanges');

      // Wywołaj callback
      if (widget.onUserDataChanged != null) {
        widget.onUserDataChanged!(newUser);
      }

      // Zamknij loading dialog
      Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dane zostały zaktualizowane',
              style: AppTextStyles.bodyText,
            ),
            backgroundColor: Colors.green.withOpacity(0.8),
            duration: const Duration(seconds: 2),
          ),
        );

        // ✅ POPRAWKA: Krótsze opóźnienie przed powrotem
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('❌ Błąd zapisywania danych: $e');
      if (mounted) {
        _showErrorSnackBar('Błąd zapisywania: ${e.toString()}');
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepBlue,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.cyan),
            const SizedBox(width: 20),
            Text(
              'Zapisuję zmiany...',
              style: AppTextStyles.bodyText,
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyText,
        ),
        backgroundColor: Colors.red.withOpacity(0.8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _deleteUserData() async {
    try {
      // Lekka wibracja przy usuwaniu
      await _hapticService.trigger(HapticType.light);

      await UserPreferencesService.clearAllUserData();
      widget.onUserDataChanged?.call(null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dane zostały usunięte',
              style: AppTextStyles.bodyText,
            ),
            backgroundColor: Colors.orange.withOpacity(0.8),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Błąd usuwania: ${e.toString()}');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepBlue,
        title: Text(
          'Niezapisane zmiany',
          style: AppTextStyles.cardTitle.copyWith(color: Colors.orange),
        ),
        content: Text(
          'Masz niezapisane zmiany. Czy chcesz wyjść bez zapisywania?',
          style: AppTextStyles.bodyTextLight,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Anuluj',
              style: AppTextStyles.bodyText.copyWith(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Wyjdź bez zapisywania',
              style: AppTextStyles.bodyText.copyWith(color: Colors.orange),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              _saveUserData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan),
            child: Text(
              'Zapisz',
              style: AppTextStyles.buttonText.copyWith(color: Colors.black),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.darkBlue,
        appBar: AppBar(
          backgroundColor: AppColors.deepBlue,
          title: Text(
            'Moje dane',
            style: AppTextStyles.sectionTitle,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Zmienione',
                  style: AppTextStyles.smallText.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                // ✅ POPRAWKA: Header pokazuje ZAPISANE dane
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
      ),
    );
  }

  // ✅ KLUCZOWA POPRAWKA: Podgląd pokazuje ZAPISANE dane, nie edytowane
  Widget _buildInfoHeader() {
    print(
        '🔍 BUILD INFO HEADER - Current saved name: ${_currentSavedUserData.name}');
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
                'Zapisane dane',
                style: AppTextStyles.cardTitle,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ POPRAWKA: Używaj _currentSavedUserData zamiast kontrolerów + debug
          _buildInfoRow('Imię', _currentSavedUserData.name),
          _buildInfoRow('Wiek', '${_currentSavedUserData.age} lat'),
          _buildInfoRow('Znak zodiaku', _currentSavedUserData.zodiacSign),
          _buildInfoRow('Data urodzenia',
              '${_currentSavedUserData.birthDate.day}.${_currentSavedUserData.birthDate.month}.${_currentSavedUserData.birthDate.year}'),
          _buildInfoRow(
              'Godzina urodzenia', _currentSavedUserData.formattedBirthTime),
          _buildInfoRow(
              'Miejsce urodzenia', _currentSavedUserData.formattedBirthPlace),
          _buildInfoRow(
              'Płeć', _getGenderDisplayName(_currentSavedUserData.gender)),
          _buildInfoRow('Dominująca ręka',
              _currentSavedUserData.dominantHand == 'left' ? 'Lewa' : 'Prawa'),

          // ✅ DODANE: Pokaż czy są niezapisane zmiany
          if (_hasUnsavedChanges) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Masz niezapisane zmiany w formularzu poniżej',
                      style:
                          AppTextStyles.caption.copyWith(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              style: AppTextStyles.caption,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyText.copyWith(
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
          color: _hasUnsavedChanges
              ? Colors.orange.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: _hasUnsavedChanges ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Edytuj dane',
                style: AppTextStyles.cardTitle,
              ),
              if (_hasUnsavedChanges) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Zmienione',
                    style: AppTextStyles.smallText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
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
          style: AppTextStyles.bodyText,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTextStyles.bodyText,
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
          style: AppTextStyles.bodyText,
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
                    style: AppTextStyles.bodyText,
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
          style: AppTextStyles.bodyText,
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
                    style: AppTextStyles.bodyText.copyWith(
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
                _onDataChanged();
              },
              activeColor: AppColors.cyan,
            ),
            Text(
              'Nie pamiętam godziny urodzenia',
              style: AppTextStyles.caption,
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
          style: AppTextStyles.bodyText,
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
          style: AppTextStyles.bodyText,
          items: const [
            DropdownMenuItem(value: 'female', child: Text('Kobieta')),
            DropdownMenuItem(value: 'male', child: Text('Mężczyzna')),
            DropdownMenuItem(value: 'other', child: Text('Inna')),
          ],
          onChanged: (v) => setState(() {
            _gender = v ?? 'other';
            _onDataChanged();
          }),
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
          style: AppTextStyles.bodyText,
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
          style: AppTextStyles.bodyText,
          items: const [
            DropdownMenuItem(value: 'right', child: Text('Prawa')),
            DropdownMenuItem(value: 'left', child: Text('Lewa')),
          ],
          onChanged: (v) => setState(() {
            _dominantHand = v ?? 'right';
            _onDataChanged();
          }),
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
          backgroundColor: _hasUnsavedChanges ? AppColors.cyan : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hasUnsavedChanges) ...[
              Icon(Icons.save, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                'Zapisz zmiany',
                style: AppTextStyles.buttonText.copyWith(color: Colors.black),
              ),
            ] else ...[
              Icon(Icons.check, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Brak zmian',
                style: AppTextStyles.buttonText.copyWith(color: Colors.white),
              ),
            ],
          ],
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
          style: AppTextStyles.cardTitle.copyWith(color: Colors.red),
        ),
        content: Text(
          'Czy na pewno chcesz usunąć wszystkie swoje dane? Ta operacja nie może zostać cofnięta.',
          style: AppTextStyles.bodyTextLight,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _hapticService.trigger(HapticType.light);
              Navigator.of(context).pop();
            },
            child: Text(
              'Anuluj',
              style: AppTextStyles.bodyText.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _hapticService.trigger(HapticType.light);
              Navigator.of(context).pop();
              _deleteUserData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Usuń',
              style: AppTextStyles.buttonText,
            ),
          ),
        ],
      ),
    );
  }
}
