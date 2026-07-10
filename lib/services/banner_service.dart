import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RemoteBanner {
  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String linkUrl;
  final String project;
  final int order;

  RemoteBanner({required this.id, required this.imageUrl, required this.title, required this.subtitle, required this.linkUrl, required this.project, required this.order});

  factory RemoteBanner.fromJson(Map<String, dynamic> j) => RemoteBanner(
    id: j['_id'] ?? '', imageUrl: j['imageUrl'] ?? '', title: j['title'] ?? '',
    subtitle: j['subtitle'] ?? '', linkUrl: j['linkUrl'] ?? '',
    project: j['project'] ?? 'All', order: j['order'] ?? 0,
  );

  Map<String, dynamic> toSlideMap() => {
    'label': title,
    'remoteImage': imageUrl,
    'image': null,
    'gradientColors': <Color>[const Color(0xFF1A0A0A), const Color(0xFF3D0000)],
    'tag': subtitle.isNotEmpty ? subtitle.toUpperCase() : 'UPDATE',
    'title': title,
    'subtitle': subtitle,
    'progress': 0.0,
    'progressLabel': '',
    'accentColor': const Color(0xFFD4AF37),
    'linkUrl': linkUrl,
  };
}

class BannerService {
  static const _api = 'https://api.roswaltsmartcue.com/api/banners';

  static Future<List<RemoteBanner>> fetchBanners({String? project}) async {
    try {
      String url = _api;
      if (project != null && project.isNotEmpty && project != 'All') {
        url = '$_api?project=${Uri.encodeComponent(project)}';
      }
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => RemoteBanner.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
