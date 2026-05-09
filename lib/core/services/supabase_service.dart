// Supabase Integration Service for Digital Vault Heritage v3.0
// Copyright © 2026 Aeternal Heritage. All rights reserved.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  late final SupabaseClient _supabase;
  late final StorageFileApi _storage;
  final Uuid _uuid = const Uuid();

  // Initialize Supabase with environment variables
  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      
      _supabase = Supabase.instance.client;
      
      _storage = _supabase.storage.from('vault-files');
      
      print('Supabase initialized successfully');
    } catch (e) {
      print('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  // Get current user session
  User? get currentUser => _supabase.auth.currentUser;

  // Sign up new user
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Sign in user
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Client-side AES-256 encryption
  Future<Map<String, dynamic>> encryptFile(File file) async {
    try {
      // Generate random encryption key
      final algorithm = AesGcm.with256bits();
      final secretKey = await algorithm.newSecretKey();
      
      // Generate random nonce
      final nonce = algorithm.newNonce();
      
      // Read file bytes
      final fileBytes = await file.readAsBytes();
      
      // Encrypt file
      final secretBox = await algorithm.encrypt(
        fileBytes,
        secretKey: secretKey,
        nonce: nonce,
      );
      
      // Convert to base64 for storage
      final encryptedData = base64Encode(secretBox.cipherText);
      final nonceBase64 = base64Encode(nonce);
      final keyBase64 = base64Encode(await secretKey.extractBytes());
      
      return {
        'encryptedData': encryptedData,
        'nonce': nonceBase64,
        'encryptionKey': keyBase64,
        'fileName': path.basename(file.path),
        'fileSize': fileBytes.length,
        'mimeType': _getMimeType(file.path),
      };
    } catch (e) {
      print('File encryption error: $e');
      rethrow;
    }
  }

  // Upload encrypted file to Supabase storage
  Future<Map<String, dynamic>> uploadEncryptedFile(File file, String userId) async {
    try {
      // Encrypt file client-side
      final encryptedInfo = await encryptFile(file);
      
      // Generate unique file path
      final fileExtension = path.extension(file.path);
      final fileName = '${_uuid.v4()}$fileExtension';
      final filePath = '$userId/$fileName';
      
      // Upload encrypted file using uploadBinary method
      final uploadResponse = await _storage.uploadBinary(
        filePath,
        base64Decode(encryptedInfo['encryptedData']),
        fileOptions: FileOptions(
          contentType: encryptedInfo['mimeType'],
          upsert: false,
        ),
      );
      
      // Store encryption metadata in database
      final metadata = {
        'id': _uuid.v4(),
        'user_id': userId,
        'file_name': encryptedInfo['fileName'],
        'file_path': filePath,
        'file_size': encryptedInfo['fileSize'],
        'mime_type': encryptedInfo['mimeType'],
        'encryption_key': encryptedInfo['encryptionKey'],
        'nonce': encryptedInfo['nonce'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final dbResponse = await _supabase
          .from('vault_files')
          .insert(metadata)
          .select();
      
      return {
        'success': true,
        'fileId': metadata['id'],
        'filePath': filePath,
        'fileName': encryptedInfo['fileName'],
        'fileSize': encryptedInfo['fileSize'],
        'uploadResponse': uploadResponse,
        'dbResponse': dbResponse,
      };
    } catch (e) {
      print('File upload error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Download and decrypt file
  Future<Map<String, dynamic>> downloadAndDecryptFile(String fileId, String userId) async {
    try {
      // Get file metadata from database
      final metadataResponse = await _supabase
          .from('vault_files')
          .select()
          .eq('id', fileId)
          .eq('user_id', userId)
          .single();
      
      if (metadataResponse.isEmpty) {
        throw Exception('File not found');
      }
      
      // Download encrypted file
      final fileData = await _storage
          .download(metadataResponse['file_path']);
      
      // Decrypt file
      final decryptedData = await decryptFile(
        base64Encode(fileData),
        metadataResponse['encryption_key'],
        metadataResponse['nonce'],
      );
      
      return {
        'success': true,
        'fileName': metadataResponse['file_name'],
        'fileData': decryptedData,
        'fileSize': metadataResponse['file_size'],
        'mimeType': metadataResponse['mime_type'],
      };
    } catch (e) {
      print('File download error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Decrypt file
  Future<Uint8List> decryptFile(
    String encryptedData,
    String encryptionKey,
    String nonce,
  ) async {
    try {
      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(base64Decode(encryptionKey));
      final nonceBytes = base64Decode(nonce);
      
      final secretBox = SecretBox(
        base64Decode(encryptedData),
        nonce: nonceBytes,
        mac: Mac.empty,
      );
      
      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      
      return Uint8List.fromList(decryptedBytes);
    } catch (e) {
      print('File decryption error: $e');
      rethrow;
    }
  }

  // List user files
  Future<List<Map<String, dynamic>>> listUserFiles(String userId) async {
    try {
      final response = await _supabase
          .from('vault_files')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('List files error: $e');
      return [];
    }
  }

  // Delete file
  Future<bool> deleteFile(String fileId, String userId) async {
    try {
      // Get file metadata
      final metadataResponse = await _supabase
          .from('vault_files')
          .select('file_path')
          .eq('id', fileId)
          .eq('user_id', userId)
          .single();
      
      if (metadataResponse.isEmpty) {
        return false;
      }
      
      // Delete from storage
      await _storage.remove([metadataResponse['file_path']]);
      
      // Delete from database
      await _supabase
          .from('vault_files')
          .delete()
          .eq('id', fileId)
          .eq('user_id', userId);
      
      return true;
    } catch (e) {
      print('Delete file error: $e');
      return false;
    }
  }

  // Update user subscription
  Future<bool> updateUserSubscription(String userId, String planType) async {
    try {
      await _supabase
          .from('user_subscriptions')
          .upsert({
            'user_id': userId,
            'plan_type': planType,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e) {
      print('Update subscription error: $e');
      return false;
    }
  }

  // Get user subscription
  Future<Map<String, dynamic>?> getUserSubscription(String userId) async {
    try {
      final response = await _supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Get subscription error: $e');
      return null;
    }
  }

  // Save heir information
  Future<bool> saveHeir(String userId, Map<String, dynamic> heirData) async {
    try {
      await _supabase
          .from('heirs')
          .insert({
            'id': _uuid.v4(),
            'user_id': userId,
            ...heirData,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e) {
      print('Save heir error: $e');
      return false;
    }
  }

  // Get user heirs
  Future<List<Map<String, dynamic>>> getUserHeirs(String userId) async {
    try {
      final response = await _supabase
          .from('heirs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get heirs error: $e');
      return [];
    }
  }

  // Save Dead Man's Switch configuration
  Future<bool> saveDeadMansSwitchConfig(String userId, Map<String, dynamic> config) async {
    try {
      await _supabase
          .from('dead_mans_switch')
          .upsert({
            'user_id': userId,
            ...config,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e) {
      print('Save DMS config error: $e');
      return false;
    }
  }

  // Get Dead Man's Switch configuration
  Future<Map<String, dynamic>?> getDeadMansSwitchConfig(String userId) async {
    try {
      final response = await _supabase
          .from('dead_mans_switch')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Get DMS config error: $e');
      return null;
    }
  }

  // Update last check-in time
  Future<bool> updateLastCheckIn(String userId) async {
    try {
      await _supabase
          .from('dead_mans_switch')
          .update({
            'last_check_in': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      
      return true;
    } catch (e) {
      print('Update check-in error: $e');
      return false;
    }
  }

  // Get MIME type based on file extension
  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.txt':
        return 'text/plain';
      case '.zip':
        return 'application/zip';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  // Get Supabase client for direct access
  SupabaseClient get supabaseClient => _supabase;

  // Get storage client for direct access
  StorageFileApi get storageClient => _storage;
}
