import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_border_radius.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

class AppDialog extends StatefulWidget {
  final Widget? header;
  final Widget content;
  final Widget? footer;

  const AppDialog({
    super.key,
    this.header,
    required this.content,
    this.footer,
  });

  @override
  State<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<AppDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _showTopShadow = false;
  bool _showBottomShadow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Check initial scroll position after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onScroll();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _showTopShadow = _scrollController.hasClients && _scrollController.offset > 10;
      _showBottomShadow = _scrollController.hasClients &&
          _scrollController.offset < _scrollController.position.maxScrollExtent - 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Center + ConstrainedBox to avoid intrinsic measurements and give
    // the dialog a sensible maximum width. Content is placed inside a
    // SingleChildScrollView with a bounded max height so children receive
    // finite constraints and don't cause layout exceptions.
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: 488.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppBorderRadius.radius(context, size: Sizes.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.header != null) widget.header!,
              
              // Top shadow indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _showTopShadow ? 8 : 0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(_showTopShadow ? 0.1 : 0),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Wrap content in a flexible scrollable area with a bounded max height
              // so long content scrolls instead of forcing unbounded layout.
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    child: widget.content,
                  ),
                ),
              ),
              
              // Bottom shadow indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _showBottomShadow ? 8 : 0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(_showBottomShadow ? 0.1 : 0),
                    ],
                  ),
                ),
              ),
              
              if (widget.footer != null) widget.footer!,
            ],
          ),
        ),
      ),
    );
  }
}
