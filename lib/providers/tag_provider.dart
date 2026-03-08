import 'package:flutter/foundation.dart';
import '../models/tag_model.dart';
import '../services/tag_service.dart';

class TagProvider extends ChangeNotifier {
  final TagService _tagService;

  List<CustomTag> _tags = [];
  bool _isListening = false;
  String? _errorMessage;

  List<CustomTag> get tags => _tags;
  String? get errorMessage => _errorMessage;

  TagProvider(this._tagService);

  void startListening() {
    if (_isListening) return;
    _isListening = true;
    _tagService.watchTags().listen(
      (tags) {
        _tags = tags;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  CustomTag? findById(String id) {
    final idx = _tags.indexWhere((t) => t.id == id);
    return idx != -1 ? _tags[idx] : null;
  }

  Future<void> addTag(String label, int bgColor, int textColor) async {
    _errorMessage = null;
    try {
      await _tagService.addTag(label, bgColor, textColor);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTag(CustomTag tag) async {
    _errorMessage = null;
    try {
      await _tagService.updateTag(tag);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTag(String tagId) async {
    _errorMessage = null;
    try {
      await _tagService.deleteTag(tagId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
