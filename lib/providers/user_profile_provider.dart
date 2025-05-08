import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:medalarmm/models/user_profile.dart';
import 'package:medalarmm/services/database_service.dart';

class UserProfileProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  UserProfile? _userProfile;
  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  // Kullanıcı profilini yükle
  Future<void> loadUserProfile() async {
    _setLoading(true);
    try {
      final userProfile = await _databaseService.getUserProfile();
      _userProfile = userProfile ?? UserProfile(name: 'Kullanıcı');
      
      // Bildirimi güvenli şekilde yapalım
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Kullanıcı profili yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Kullanıcı profilini güncelle
  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    _setLoading(true);
    try {
      await _databaseService.saveUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      
      // Bildirimi güvenli şekilde yapalım
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Kullanıcı profili güncellenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Acil durum kişisi ekle
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    if (_userProfile == null) {
      await loadUserProfile();
    }
    
    _setLoading(true);
    try {
      _userProfile!.emergencyContacts.add(contact);
      await _databaseService.saveUserProfile(_userProfile!);
      
      // Bildirimi güvenli şekilde yapalım
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Acil durum kişisi eklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Acil durum kişisini güncelle
  Future<void> updateEmergencyContact(int index, EmergencyContact updatedContact) async {
    if (_userProfile == null || index >= _userProfile!.emergencyContacts.length) {
      return;
    }
    
    _setLoading(true);
    try {
      _userProfile!.emergencyContacts[index] = updatedContact;
      await _databaseService.saveUserProfile(_userProfile!);
      
      // Bildirimi güvenli şekilde yapalım
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Acil durum kişisi güncellenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Acil durum kişisini sil
  Future<void> removeEmergencyContact(int index) async {
    if (_userProfile == null || index >= _userProfile!.emergencyContacts.length) {
      return;
    }
    
    _setLoading(true);
    try {
      _userProfile!.emergencyContacts.removeAt(index);
      await _databaseService.saveUserProfile(_userProfile!);
      
      // Bildirimi güvenli şekilde yapalım
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Acil durum kişisi silinirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Yükleme durumunu güncelle
  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Aynı değeri tekrar ayarlamaya gerek yok
    _isLoading = loading;
    
    // WidgetsBinding.instance.addPostFrameCallback kullanarak
    // notifyListeners'ı mevcut frame bittikten sonra çağıralım
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}