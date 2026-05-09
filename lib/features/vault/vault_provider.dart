// v2.5 - Enhanced vault provider with comprehensive error handling and security
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logger.dart';
import '../../core/services/error_handling_service.dart';
import '../../core/services/security_service.dart';
import '../../shared/models/vault_doc.dart';

final vaultProvider =
    AsyncNotifierProvider<VaultNotifier, List<VaultDoc>>(VaultNotifier.new);

class VaultNotifier extends AsyncNotifier<List<VaultDoc>> {
  static const _key = 'aeterna_vault_docs';
  static const _maxVaultSize = 100; // Maximum number of documents
  static const _maxDocumentSize = 100 * 1024 * 1024; // 100MB per document
  
  final ErrorHandlingService _errorService = ErrorHandlingService();
  final SecurityService _security = SecurityService();

  @override
  Future<List<VaultDoc>> build() => _load();

  Future<List<VaultDoc>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      
      // Validate data integrity
      final list = jsonDecode(raw) as List<dynamic>;
      final docs = list
          .map((e) => VaultDoc.fromJson(e as Map<String, dynamic>))
          .where((doc) => _isValidDocument(doc))
          .toList();
      
      AppLogger.info('Loaded ${docs.length} vault documents');
      return docs;
    } catch (e, st) {
      await _errorService.handleError(
        e,
        stackTrace: st,
        category: ErrorCategory.storage,
        context: {'operation': 'vault_load'},
      );
      rethrow;
    }
  }

  Future<void> _save(List<VaultDoc> docs) async {
    try {
      // Validate before saving
      if (docs.length > _maxVaultSize) {
        throw ArgumentError('Vault size exceeds maximum limit of $_maxVaultSize documents');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key, 
        jsonEncode(docs.map((d) => d.toJson()).toList()),
      );
    } catch (e, st) {
      await _errorService.handleError(
        e,
        stackTrace: st,
        category: ErrorCategory.storage,
        context: {'operation': 'vault_save', 'docCount': docs.length},
      );
      rethrow;
    }
  }

  Future<void> addDoc(VaultDoc doc) async {
    try {
      // Validate document
      _validateDocument(doc);
      
      final current = await future;
      
      // Check vault size limit
      if (current.length >= _maxVaultSize) {
        throw StateError('Vault is full. Maximum $_maxVaultSize documents allowed.');
      }
      
      // Check for duplicates
      if (current.any((d) => d.name == doc.name && d.extension == doc.extension)) {
        throw ArgumentError('A document with the same name already exists.');
      }
      
      final updated = [...current, doc];
      await _save(updated);
      state = AsyncData(updated);
      
      AppLogger.info('Document added to vault: ${doc.name}');
    } catch (e, st) {
      await _errorService.handleError(
        e,
        stackTrace: st,
        category: ErrorCategory.validation,
        context: {
          'operation': 'vault_add_doc',
          'docName': doc.name,
          'docSize': doc.sizeBytes,
        },
        suggestedActions: [
          'Check document name and size',
          'Remove unused documents to free space',
          'Verify document format is supported',
        ],
      );
      state = AsyncError(e, st);
    }
  }

  Future<void> removeDoc(String id) async {
    try {
      // Sanitize input
      id = _security.sanitizeInput(id);
      
      final current = await future;
      final docToRemove = current.where((d) => d.id == id).firstOrNull;
      
      if (docToRemove == null) {
        throw ArgumentError('Document not found');
      }
      
      final updated = current.where((d) => d.id != id).toList();
      await _save(updated);
      state = AsyncData(updated);
      
      AppLogger.info('Document removed from vault: ${docToRemove.name}');
    } catch (e, st) {
      await _errorService.handleError(
        e,
        stackTrace: st,
        category: ErrorCategory.validation,
        context: {'operation': 'vault_remove_doc', 'docId': id},
        suggestedActions: [
          'Verify the document exists',
          'Refresh the vault and try again',
          'Check your permissions',
        ],
      );
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleHeirShare(String id) async {
    try {
      // Sanitize input
      id = _security.sanitizeInput(id);
      
      final current = await future;
      final doc = current.where((d) => d.id == id).firstOrNull;
      
      if (doc == null) {
        throw ArgumentError('Document not found');
      }
      
      final updated = current.map((d) {
        if (d.id != id) return d;
        return d.copyWith(isSharedWithHeirs: !d.isSharedWithHeirs);
      }).toList();
      
      await _save(updated);
      state = AsyncData(updated);
      
      AppLogger.info('Heir share toggled for document: ${doc.name}');
    } catch (e, st) {
      await _errorService.handleError(
        e,
        stackTrace: st,
        category: ErrorCategory.validation,
        context: {'operation': 'vault_toggle_heir_share', 'docId': id},
        suggestedActions: [
          'Verify the document exists',
          'Check your sharing permissions',
          'Refresh the vault and try again',
        ],
      );
      state = AsyncError(e, st);
    }
  }

  Future<void> updateDocument(String id, VaultDoc updatedDoc) async {
    try {
      // Sanitize input
      id = _security.sanitizeInput(id);
      _validateDocument(updatedDoc);
      
      final current = await future;
      final docIndex = current.indexWhere((d) => d.id == id);
      
      if (docIndex == -1) {
        throw ArgumentError('Document not found');
      }
      
      final updated = List<VaultDoc>.from(current);
      updated[docIndex] = updatedDoc;
      
      await _save(updated);
      state = AsyncData(updated);
      
      AppLogger.info('Document updated: ${updatedDoc.name}');
    } catch (e, st) {
      await _errorService.handleError(
        e,
        stackTrace: st,
        category: ErrorCategory.validation,
        context: {
          'operation': 'vault_update_doc',
          'docId': id,
          'docName': updatedDoc.name,
        },
        suggestedActions: [
          'Verify document data is valid',
          'Check your editing permissions',
          'Ensure document format is supported',
        ],
      );
      state = AsyncError(e, st);
    }
  }

  Future<void> clearVault() async {
    try {
      await _save([]);
      state = const AsyncData([]);
      
      AppLogger.info('Vault cleared');
    } catch (e, st) {
      await _errorService.handleError(
        e,
        stackTrace: st,
        category: ErrorCategory.storage,
        context: {'operation': 'vault_clear'},
        suggestedActions: [
          'Check your storage permissions',
          'Restart the application',
          'Contact support if the issue persists',
        ],
      );
      state = AsyncError(e, st);
    }
  }

  /// Validate document before adding/updating
  void _validateDocument(VaultDoc doc) {
    // Sanitize document name
    final sanitizedName = _security.sanitizeInput(doc.name, maxLength: 255);
    if (sanitizedName != doc.name) {
      throw ArgumentError('Document name contains invalid characters');
    }
    
    // Check document size
    if (doc.sizeBytes > _maxDocumentSize) {
      throw ArgumentError('Document size exceeds maximum limit of ${_maxDocumentSize ~/ (1024 * 1024)}MB');
    }
    
    if (doc.sizeBytes <= 0) {
      throw ArgumentError('Document size must be greater than 0');
    }
    
    // Validate file extension
    if (doc.extension.isEmpty) {
      throw ArgumentError('File extension is required');
    }
    
    // Validate URL format
    if (doc.ciphertextUrl.isEmpty) {
      throw ArgumentError('Document URL is required');
    }
  }

  /// Check if document is valid during loading
  bool _isValidDocument(VaultDoc doc) {
    try {
      _validateDocument(doc);
      return true;
    } catch (e) {
      AppLogger.warning('Invalid document found during load: ${doc.id} - Error: $e');
      return false;
    }
  }

  /// Get vault statistics
  Map<String, dynamic> getVaultStats() {
    final current = state.value ?? [];
    final totalSize = current.fold<int>(0, (sum, doc) => sum + doc.sizeBytes);
    final sharedCount = current.where((doc) => doc.isSharedWithHeirs).length;
    
    return {
      'totalDocuments': current.length,
      'totalSize': totalSize,
      'sharedDocuments': sharedCount,
      'maxDocuments': _maxVaultSize,
      'maxDocumentSize': _maxDocumentSize,
      'utilization': '${(current.length / _maxVaultSize * 100).toStringAsFixed(1)}%',
    };
  }
}
