import 'package:flutter/material.dart';

class PropertyPost {
  const PropertyPost({
    this.id = '',
    this.ownerId = '',
    required this.platform,
    required this.seller,
    required this.age,
    required this.title,
    required this.type,
    required this.deal,
    this.video = false,
    this.height = 130,
    this.color = const Color(0xFF8A7650),
    this.price = '',
    this.location = '',
    this.description = '',
    this.socialUrl = '',
    this.imagePaths = const [],
    this.isUserPost = false,
    this.sellerPhone = '',
    this.area = '',
    this.bedrooms = '',
    this.bathrooms = '',
  });

  final String id;
  final String ownerId;
  final String platform, seller, age, title, type, deal;
  final bool video;
  final double height;
  final Color color;
  final String price, location, description, socialUrl;
  final String sellerPhone, area, bedrooms, bathrooms;
  final List<String> imagePaths;
  final bool isUserPost;

  factory PropertyPost.fromJson(
    Map<String, dynamic> json, {
    bool isUserPost = false,
  }) {
    final createdAt = DateTime.tryParse(json['age'] as String? ?? '');
    return PropertyPost(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      platform: json['platform'] as String? ?? 'PlotPost',
      seller: json['seller'] as String? ?? 'PlotPost user',
      age: createdAt == null ? 'Just now' : _timeAgo(createdAt),
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      deal: json['deal'] as String? ?? '',
      price: json['price'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      socialUrl: json['socialUrl'] as String? ?? '',
      imagePaths: List<String>.from(json['imagePaths'] as List? ?? const []),
      isUserPost: isUserPost,
      sellerPhone: json['sellerPhone'] as String? ?? '',
      area: json['area'] as String? ?? '',
      bedrooms: json['bedrooms'] as String? ?? '',
      bathrooms: json['bathrooms'] as String? ?? '',
    );
  }

  static String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  String get storageKey => '\u001f$platform\u001f$seller\u001f$title';

  /// Extracted seller initials for avatar display
  String get initials {
    final trimmed = seller.trim();
    if (trimmed.isEmpty) return 'P';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// First segment of location string before comma
  String get shortLocation {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return '';
    final idx = trimmed.indexOf(',');
    return idx == -1 ? trimmed : trimmed.substring(0, idx);
  }

  /// Pre-formatted search string for high-performance filtering
  String get searchableText {
    return '$title $type $deal $seller $platform $location'.toLowerCase();
  }
}
