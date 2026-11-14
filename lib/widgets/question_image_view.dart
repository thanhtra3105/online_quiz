// lib/widgets/question_image_view.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Hiển thị một hoặc nhiều hình ảnh của câu hỏi với bo góc, khung viền, hỗ trợ Base64 & Network URL, phóng to ảnh
class QuestionImageView extends StatefulWidget {
  final String? imageUrl;
  final List<String>? imageUrls;
  final double maxHeight;
  final double? maxWidth;
  final bool allowZoom;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onDelete;
  final VoidCallback? onChange;
  final void Function(int index)? onDeleteIndex;
  final void Function(int index)? onChangeIndex;
  final VoidCallback? onAddMore;
  final bool isEditable;

  const QuestionImageView({
    super.key,
    this.imageUrl,
    this.imageUrls,
    this.maxHeight = 280,
    this.maxWidth,
    this.allowZoom = true,
    this.margin,
    this.onDelete,
    this.onChange,
    this.onDeleteIndex,
    this.onChangeIndex,
    this.onAddMore,
    this.isEditable = false,
  });

  /// Bộ nhớ đệm tĩnh lưu trữ bytes của ảnh Base64 để tránh decode lại nhiều lần gây chớp nháy (flicker)
  static final Map<String, Uint8List> base64Cache = <String, Uint8List>{};

  /// Lấy hoặc decode bytes của ảnh Base64
  static Uint8List? getOrDecodeBase64(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith('data:image')) return null;

    if (base64Cache.containsKey(trimmed)) {
      return base64Cache[trimmed];
    }

    final commaIndex = trimmed.indexOf(',');
    if (commaIndex != -1) {
      try {
        final base64String = trimmed.substring(commaIndex + 1);
        final bytes = base64Decode(base64String);
        if (base64Cache.length > 120) {
          base64Cache.remove(base64Cache.keys.first);
        }
        base64Cache[trimmed] = bytes;
        return bytes;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Widget tĩnh hiển thị ảnh thông minh: tự nhận diện Data URI (Base64) hoặc Network URL (HTTP/HTTPS)
  static Widget buildImageWidget(
    BuildContext context,
    String url, {
    BoxFit fit = BoxFit.contain,
  }) {
    final trimmed = url.trim();
    final isDark = AppConstants.isDarkMode(context);

    // 1. Nếu là ảnh Base64 Data URI (data:image/...)
    if (trimmed.startsWith('data:image')) {
      final bytes = getOrDecodeBase64(trimmed);
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          key: ValueKey(bytes.hashCode),
          fit: fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context, isDark),
        );
      }
      return _buildErrorWidget(context, isDark);
    }

    // 2. Nếu là URL mạng thông thường (http://, https://)
    return Image.network(
      trimmed,
      key: ValueKey(trimmed),
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 140,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2.5,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context, isDark),
    );
  }

  static Widget _buildErrorWidget(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 110,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, color: Color(0xFFDC2626), size: 30),
          const SizedBox(height: 6),
          Text(
            'Không thể hiển thị hình ảnh',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDark ? Colors.red.shade300 : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<QuestionImageView> createState() => _QuestionImageViewState();
}

class _QuestionImageViewState extends State<QuestionImageView> {
  List<String> get _images {
    if (widget.imageUrls != null && widget.imageUrls!.isNotEmpty) {
      return widget.imageUrls!.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty) {
      return [widget.imageUrl!.trim()];
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _preloadBase64Images();
  }

  @override
  void didUpdateWidget(covariant QuestionImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _preloadBase64Images();
  }

  void _preloadBase64Images() {
    for (final url in _images) {
      if (url.startsWith('data:image')) {
        QuestionImageView.getOrDecodeBase64(url);
      }
    }
  }

  void _showZoomDialog(BuildContext context, String targetUrl) {
    if (targetUrl.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: QuestionImageView.buildImageWidget(context, targetUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleCard(BuildContext context, String url, int index, int totalCount) {
    final isDark = AppConstants.isDarkMode(context);

    Widget imageContent = Container(
      constraints: BoxConstraints(
        maxHeight: widget.maxHeight,
        maxWidth: widget.maxWidth ?? double.infinity,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppConstants.border(context) : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          QuestionImageView.buildImageWidget(context, url, fit: BoxFit.contain),
          if (widget.allowZoom)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.zoom_in_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          // Huy hiệu số thứ tự ảnh nếu câu hỏi có nhiều hơn 1 ảnh
          if (totalCount > 1)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Hình ${index + 1}/$totalCount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.allowZoom) {
      imageContent = Tooltip(
        message: 'Bấm để phóng to ảnh',
        child: InkWell(
          onTap: () => _showZoomDialog(context, url),
          borderRadius: BorderRadius.circular(12),
          child: imageContent,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        imageContent,
        if (widget.isEditable) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (widget.onChangeIndex != null || widget.onChange != null)
                TextButton.icon(
                  onPressed: () {
                    if (widget.onChangeIndex != null) {
                      widget.onChangeIndex!(index);
                    } else if (widget.onChange != null) {
                      widget.onChange!();
                    }
                  },
                  icon: Icon(Icons.sync_rounded, size: 16, color: AppConstants.brand(context)),
                  label: Text(
                    totalCount > 1 ? 'Đổi hình ${index + 1}' : 'Đổi ảnh khác',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.brand(context),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              const SizedBox(width: 8),
              if (widget.onDeleteIndex != null || widget.onDelete != null)
                TextButton.icon(
                  onPressed: () {
                    if (widget.onDeleteIndex != null) {
                      widget.onDeleteIndex!(index);
                    } else if (widget.onDelete != null) {
                      widget.onDelete!();
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                  label: Text(
                    totalCount > 1 ? 'Xóa hình ${index + 1}' : 'Xóa ảnh',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = AppConstants.isDarkMode(context);

    return Padding(
      padding: widget.margin ?? const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hiển thị từng ảnh trong danh sách
          for (int i = 0; i < images.length; i++) ...[
            _buildSingleCard(context, images[i], i, images.length),
            if (i < images.length - 1) const SizedBox(height: 14),
          ],

          // Nút thêm ảnh khác (chỉ hiện khi đang ở chế độ chỉnh sửa)
          if (widget.isEditable && widget.onAddMore != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: widget.onAddMore,
              icon: Icon(Icons.add_photo_alternate_rounded, size: 16, color: AppConstants.brand(context)),
              label: Text(
                'Thêm ảnh khác cho câu này (${images.length} ảnh hiện có)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.brand(context),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFFBFDBFE)),
                backgroundColor: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper tiện ích cho việc thêm hình ảnh câu hỏi (Tải từ thiết bị tối đa 10MB hoặc nhập URL)
class QuestionImageHelper {
  /// Hiển thị hộp thoại Modal Dialog Ở TRUNG TÂM MÀN HÌNH cho phép chọn tải ảnh từ máy tính hoặc dán URL
  static Future<String?> pickOrEnterImageUrl(BuildContext context) async {
    final isDark = AppConstants.isDarkMode(context);

    // Bước 1: Mở Dialog CĂN GIỮA TRUNG TÂM MÀN HÌNH
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppConstants.surf(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppConstants.border(ctx)),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfHigh(ctx) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.image_rounded, color: AppConstants.brand(ctx), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Thêm hình ảnh cho câu hỏi',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.txt(ctx),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Hình ảnh sẽ hiển thị kèm theo nội dung câu hỏi cho thí sinh khi làm bài.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppConstants.txtMuted(ctx),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Lựa chọn 1: Tải từ thiết bị (Hỗ trợ file lên tới 10MB)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppConstants.border(ctx)),
                  ),
                  tileColor: AppConstants.surfLow(ctx),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.file_upload_outlined, color: Color(0xFF10B981), size: 22),
                  ),
                  title: Text(
                    'Tải ảnh từ máy tính / thiết bị',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.txt(ctx),
                    ),
                  ),
                  subtitle: Text(
                    'Chọn ảnh JPG, PNG, GIF, WebP (Dung lượng tối đa 10MB)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppConstants.txtMuted(ctx),
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, 'device'),
                ),

                const SizedBox(height: 12),

                // Lựa chọn 2: Nhập đường dẫn ảnh URL
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppConstants.border(ctx)),
                  ),
                  tileColor: AppConstants.surfLow(ctx),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(ctx).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.link_rounded, color: AppConstants.brand(ctx), size: 22),
                  ),
                  title: Text(
                    'Nhập liên kết ảnh (URL)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.txt(ctx),
                    ),
                  ),
                  subtitle: Text(
                    'Dán trực tiếp URL ảnh từ Internet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppConstants.txtMuted(ctx),
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, 'url'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Bước 2: Thực hiện hành động sau khi đóng dialog
    if (!context.mounted || choice == null) return null;

    if (choice == 'device') {
      return _uploadImageFromDevice(context);
    } else if (choice == 'url') {
      return _showUrlInputDialog(context);
    }

    return null;
  }

  /// Tối ưu hóa dung lượng ảnh: nếu ảnh > 250KB thì tự động co kích thước tối đa 1100px để vừa vặn với Firestore
  static Future<Uint8List> _optimizeImageBytes(Uint8List originalBytes) async {
    if (originalBytes.length <= 250 * 1024) {
      return originalBytes;
    }
    try {
      final codec = await ui.instantiateImageCodec(
        originalBytes,
        targetWidth: 1100,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final resized = byteData.buffer.asUint8List();
        if (resized.length < originalBytes.length) {
          return resized;
        }
      }
    } catch (_) {}
    return originalBytes;
  }

  /// Chọn file ảnh từ máy (Tối đa 10MB) và mã hóa thành Data URI
  static Future<String?> _uploadImageFromDevice(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể đọc dữ liệu file đã chọn'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return null;
      }

      // Giới hạn nâng lên 10MB theo yêu cầu người dùng
      if (bytes.length > 10 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kích thước ảnh vượt quá giới hạn 10MB. Vui lòng chọn ảnh nhỏ hơn!'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return null;
      }

      // Tối ưu hóa dung lượng (resize nếu cần)
      final optimizedBytes = await _optimizeImageBytes(bytes);

      if (optimizedBytes.length > 800 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dung lượng ảnh sau nén vẫn > 800KB. Vui lòng dùng liên kết URL cho ảnh này.'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return null;
      }

      // Tạo Data URL
      final ext = file.extension?.toLowerCase() ?? 'png';
      final mime = ext == 'jpg' || ext == 'jpeg'
          ? 'image/jpeg'
          : (ext == 'webp'
              ? 'image/webp'
              : (ext == 'gif' ? 'image/gif' : 'image/png'));

      final base64String = base64Encode(optimizedBytes);
      final dataUrl = 'data:$mime;base64,$base64String';

      // Lưu ngay vào cache để khi widget vẽ lần đầu là có sẵn bytes
      QuestionImageView.base64Cache[dataUrl] = optimizedBytes;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Đã đính kèm ảnh vào câu hỏi thành công!'),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1800),
          ),
        );
      }

      return dataUrl;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đính kèm ảnh: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  /// Hiển thị dialog nhập URL ảnh
  static Future<String?> promptForImageUrl(BuildContext context, {String? initialUrl}) async {
    return _showUrlInputDialog(context, initialUrl: initialUrl);
  }

  static Future<String?> _showUrlInputDialog(BuildContext context, {String? initialUrl}) async {
    final controller = TextEditingController(text: initialUrl ?? '');
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surf(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.border(ctx)),
        ),
        title: Row(
          children: [
            Icon(Icons.link_rounded, color: AppConstants.brand(ctx)),
            const SizedBox(width: 10),
            Text(
              'Nhập liên kết ảnh (URL)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.txt(ctx),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dán đường dẫn trực tiếp đến hình ảnh (bắt đầu bằng http:// hoặc https://):',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppConstants.txtMuted(ctx),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'https://example.com/image.png',
                  prefixIcon: const Icon(Icons.image_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: AppConstants.surfLow(ctx),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập đường dẫn ảnh';
                  }
                  final trimmed = val.trim().toLowerCase();
                  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                    return 'Đường dẫn phải bắt đầu bằng http:// hoặc https://';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppConstants.border(ctx)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hủy', style: TextStyle(color: AppConstants.txt(ctx))),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.brand(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
