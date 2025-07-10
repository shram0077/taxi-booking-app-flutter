import 'dart:io';
import 'package:dio/dio.dart';

class FileLuApiService {
  final Dio _dio = Dio();
  final String _apiKey;

  FileLuApiService(this._apiKey);

  Future<Map<String, String>> _getUploadServer() async {
    final url = 'https://filelu.com/api/upload/server?key=$_apiKey';
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['status'] == 200) {
        return {
          'upload_url': response.data['result'],
          'sess_id': response.data['sess_id'],
        };
      } else {
        throw Exception(
            'Failed to fetch upload server: ${response.data['msg']}');
      }
    } catch (e) {
      throw Exception('Error fetching upload server: $e');
    }
  }

  Future<String> _getDirectLink(String fileCode) async {
    final url =
        'https://filelu.com/api/file/direct_link?key=$_apiKey&file_code=$fileCode';
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['status'] == 200) {
        return response.data['result']['url'];
      } else {
        throw Exception('Failed to get direct link: ${response.data['msg']}');
      }
    } catch (e) {
      throw Exception('Error fetching direct link: $e');
    }
  }

  Future<String> uploadImage({
    required File imageFile,
    required String fileName,
    required Function(double) onProgress,
  }) async {
    final serverInfo = await _getUploadServer();
    final uploadUrl = serverInfo['upload_url']!;
    final sessId = serverInfo['sess_id']!;

    final formData = FormData.fromMap({
      'sess_id': sessId,
      'utype': 'prem',
      'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });

    final response = await _dio.post(
      uploadUrl,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) {
          onProgress(sent / total);
        }
      },
    );

    if (response.statusCode == 200) {
      final fileCode = response.data[0]['file_code'];
      final downloadUrl = await _getDirectLink(fileCode);
      return downloadUrl;
    } else {
      throw Exception('Image upload failed');
    }
  }
}
