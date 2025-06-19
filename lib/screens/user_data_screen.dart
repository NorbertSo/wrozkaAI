import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';

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
  late DateTime _birthDate;
  late String _gender;
  late String _dominantHand;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData.name);
    _birthDate = widget.userData.birthDate;
    _gender = widget.userData.gender;
    _dominantHand = widget.userData.dominantHand;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _saveUserData() async {
    final newUser = UserData(
      name: _nameController.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      dominantHand: _dominantHand,
      registrationDate: widget.userData.registrationDate,
    );
    // Możesz tu dodać zapis do shared_preferences lub innego storage
    widget.onUserDataChanged?.call(newUser);
    Navigator.of(context).pop();
  }

  void _deleteUserData() async {
    // Możesz tu dodać usuwanie z shared_preferences
    widget.onUserDataChanged?.call(null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje dane'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Usuń dane'),
                  content: const Text('Czy na pewno chcesz usunąć swoje dane?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Anuluj'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Usuń'),
                    ),
                  ],
                ),
              );
              if (confirm == true) _deleteUserData();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Imię'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickBirthDate,
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(labelText: 'Data urodzenia'),
                      child: Text(
                          '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Płeć'),
              items: const [
                DropdownMenuItem(value: 'female', child: Text('Kobieta')),
                DropdownMenuItem(value: 'male', child: Text('Mężczyzna')),
                DropdownMenuItem(
                    value: 'other', child: Text('Inna/nie podaję')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'other'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _dominantHand,
              decoration: const InputDecoration(labelText: 'Dominująca ręka'),
              items: const [
                DropdownMenuItem(value: 'right', child: Text('Prawa')),
                DropdownMenuItem(value: 'left', child: Text('Lewa')),
              ],
              onChanged: (v) => setState(() => _dominantHand = v ?? 'right'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveUserData,
                child: const Text('Zapisz zmiany'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
