import 'package:flutter/material.dart';
import 'package:medalarmm/constants/app_constants.dart';
import 'package:medalarmm/models/user_profile.dart';
import 'package:medalarmm/providers/user_profile_provider.dart';
import 'package:medalarmm/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _medicalConditionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _medicalConditionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final provider = Provider.of<UserProfileProvider>(context, listen: false);
    await provider.loadUserProfile();
    
    if (provider.userProfile != null) {
      _nameController.text = provider.userProfile!.name;
      _ageController.text = provider.userProfile!.age.toString();
      _medicalConditionController.text = provider.userProfile!.medicalCondition ?? '';
      _notesController.text = provider.userProfile!.notes ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Consumer<UserProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserProfileSection(provider),
                const SizedBox(height: AppDimens.paddingL),
                _buildEmergencyContactsSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserProfileSection(UserProfileProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 30,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.userProfile?.name.isNotEmpty == true
                            ? provider.userProfile!.name
                            : 'İsim Girilmemiş',
                        style: AppTextStyles.heading2,
                      ),
                      if (provider.userProfile?.age != null &&
                          (provider.userProfile!.age ?? 0) > 0) ...[
                        const SizedBox(height: AppDimens.paddingXS),
                        Text(
                          '${provider.userProfile!.age} yaşında',
                          style: AppTextStyles.bodyTextSmall,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProfileDialog(provider),
                ),
              ],
            ),
            if (provider.userProfile?.medicalCondition?.isNotEmpty == true) ...[
              const SizedBox(height: AppDimens.paddingM),
              const Divider(),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                'Sağlık Durumu',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                provider.userProfile!.medicalCondition!,
                style: AppTextStyles.bodyText,
              ),
            ],
            if (provider.userProfile?.notes?.isNotEmpty == true) ...[
              const SizedBox(height: AppDimens.paddingM),
              const Divider(),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                'Notlar',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                provider.userProfile!.notes!,
                style: AppTextStyles.bodyText,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactsSection(UserProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Acil Durum Kişileri',
              style: AppTextStyles.heading2,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              onPressed: () => _showAddEmergencyContactDialog(provider),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),
        if (provider.userProfile?.emergencyContacts.isEmpty == true)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppDimens.paddingL),
                const Icon(
                  Icons.contact_emergency,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppDimens.paddingM),
                Text(
                  'Henüz acil durum kişisi eklenmemiş',
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                ElevatedButton(
                  onPressed: () => _showAddEmergencyContactDialog(provider),
                  child: const Text('Acil Durum Kişisi Ekle'),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.userProfile!.emergencyContacts.length,
            itemBuilder: (context, index) {
              final contact = provider.userProfile!.emergencyContacts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.secondary,
                            child: Icon(
                              Icons.contact_phone,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: AppTextStyles.heading3,
                                ),
                                const SizedBox(height: AppDimens.paddingXS),
                                Text(
                                  contact.relationship ?? '',
                                  style: AppTextStyles.bodyTextSmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditEmergencyContactDialog(
                              provider,
                              index,
                              contact,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: AppColors.error,
                            onPressed: () => _showDeleteEmergencyContactDialog(
                              provider,
                              index,
                              contact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _callPhoneNumber(contact.phoneNumber),
                              icon: const Icon(Icons.phone),
                              label: const Text('Ara'),
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _sendSms(contact.phoneNumber),
                              icon: const Icon(Icons.message),
                              label: const Text('Mesaj'),
                            ),
                          ),
                        ],
                      ),
                      if (contact.email?.isNotEmpty == true) ...[
                        const SizedBox(height: AppDimens.paddingS),
                        OutlinedButton.icon(
                          onPressed: () => _sendEmail(contact.email!),
                          icon: const Icon(Icons.email),
                          label: const Text('E-posta Gönder'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimens.paddingS),
                      SwitchListTile(
                        title: const Text(
                          'Doz alınmadığında bilgilendir',
                          style: AppTextStyles.bodyTextSmall,
                        ),
                        value: contact.notifyOnMissedDoses,
                        onChanged: (value) {
                          final updatedContact = EmergencyContact(
                            name: contact.name,
                            relationship: contact.relationship,
                            phoneNumber: contact.phoneNumber,
                            email: contact.email ?? '',
                            notifyOnMissedDoses: value,
                          );
                          provider.updateEmergencyContact(index, updatedContact);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showEditProfileDialog(UserProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profili Düzenle'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adınızı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Yaş',
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen yaşınızı girin';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age <= 0 || age > 120) {
                        return 'Geçerli bir yaş girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _medicalConditionController,
                    decoration: const InputDecoration(
                      labelText: 'Sağlık Durumu (Opsiyonel)',
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notlar (Opsiyonel)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final updatedProfile = UserProfile(
                    name: _nameController.text,
                    dateOfBirth: provider.userProfile?.dateOfBirth,
                    weight: provider.userProfile?.weight,
                    height: provider.userProfile?.height,
                    allergies: provider.userProfile?.allergies,
                    medicalConditions: _medicalConditionController.text.isEmpty
                        ? {}
                        : {'Genel': _medicalConditionController.text},
                    healthNotes: _notesController.text.isEmpty
                        ? {}
                        : {'Genel': _notesController.text},
                    emergencyContacts:
                        provider.userProfile?.emergencyContacts ?? [],
                  );
                  provider.updateUserProfile(updatedProfile);
                  Navigator.pop(context);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEmergencyContactDialog(UserProfileProvider provider) {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    bool notifyOnMissedDoses = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Acil Durum Kişisi Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: relationshipController,
                      decoration: const InputDecoration(
                        labelText: 'Yakınlık',
                        prefixIcon: Icon(Icons.people),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta (Opsiyonel)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    SwitchListTile(
                      title: const Text(
                        'Doz alınmadığında bilgilendir',
                      ),
                      value: notifyOnMissedDoses,
                      onChanged: (value) {
                        setState(() {
                          notifyOnMissedDoses = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        relationshipController.text.isNotEmpty &&
                        phoneController.text.isNotEmpty) {
                      final newContact = EmergencyContact(
                        name: nameController.text,
                        relationship: relationshipController.text,
                        phoneNumber: phoneController.text,
                        email: emailController.text.isEmpty
                            ? null
                            : emailController.text,
                        notifyOnMissedDoses: notifyOnMissedDoses,
                      );
                      provider.addEmergencyContact(newContact);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen tüm zorunlu alanları doldurun'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditEmergencyContactDialog(
    UserProfileProvider provider,
    int index,
    EmergencyContact contact,
  ) {
    final nameController = TextEditingController(text: contact.name);
    final relationshipController =
        TextEditingController(text: contact.relationship);
    final phoneController = TextEditingController(text: contact.phoneNumber);
    final emailController = TextEditingController(text: contact.email ?? '');
    bool notifyOnMissedDoses = contact.notifyOnMissedDoses;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Acil Durum Kişisini Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: relationshipController,
                      decoration: const InputDecoration(
                        labelText: 'Yakınlık',
                        prefixIcon: Icon(Icons.people),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta (Opsiyonel)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    SwitchListTile(
                      title: const Text(
                        'Doz alınmadığında bilgilendir',
                      ),
                      value: notifyOnMissedDoses,
                      onChanged: (value) {
                        setState(() {
                          notifyOnMissedDoses = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        relationshipController.text.isNotEmpty &&
                        phoneController.text.isNotEmpty) {
                      final updatedContact = EmergencyContact(
                        name: nameController.text,
                        relationship: relationshipController.text,
                        phoneNumber: phoneController.text,
                        email: emailController.text.isEmpty
                            ? null
                            : emailController.text,
                        notifyOnMissedDoses: notifyOnMissedDoses,
                      );
                      provider.updateEmergencyContact(index, updatedContact);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen tüm zorunlu alanları doldurun'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Güncelle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteEmergencyContactDialog(
    UserProfileProvider provider,
    int index,
    EmergencyContact contact,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Acil Durum Kişisini Sil'),
          content: Text(
            '${contact.name} kişisini silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.removeEmergencyContact(index);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callPhoneNumber(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telefon araması başlatılamadı'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    final url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS gönderilemedi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta gönderilemedi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}