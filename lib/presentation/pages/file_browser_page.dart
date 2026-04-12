import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';
import 'package:ftpulse/core/ui/animations/fade_slide_item.dart';
import 'package:ftpulse/presentation/widgets/modals/create_entity_modal.dart';
import 'package:ftpulse/presentation/widgets/modals/file_actions_modal.dart';
import 'package:ftpulse/presentation/widgets/modals/folder_actions_modal.dart';
import 'package:ftpulse/presentation/widgets/modals/upload_entity_modal.dart';

class FileBrowserPage extends StatelessWidget {
  final ServerConnection connection;

  const FileBrowserPage({super.key, required this.connection});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FileBrowserProvider(connection)..init(),
      child: const _FileBrowserLayout(),
    );
  }
}

class _FileBrowserLayout extends StatefulWidget {
  const _FileBrowserLayout();

  @override
  State<_FileBrowserLayout> createState() =>
      _FileBrowserLayoutState();
}

class _FileBrowserLayoutState extends State<_FileBrowserLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;

  bool _isSearchActive = false;
  final TextEditingController _searchController =
      TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    Haptics.selection();
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (_isSearchActive) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileBrowserProvider>();

    if (provider.isLoading) {
      _fabController.reverse();
    } else {
      _fabController.forward();
    }

    void handleBack() {
      if (_isSearchActive) {
        _toggleSearch();
        return;
      }

      if (provider.isLoading) {
        provider.cancelLoading();
        if (provider.files.isEmpty) Navigator.of(context).pop();
        return;
      }
      final canGoUp = provider.navigateUp();
      if (!canGoUp) Navigator.of(context).pop();
    }

    String getTitle() {
      if (_isSearchActive) return 'Search';
      if (provider.currentPath == '/' ||
          provider.currentPath.isEmpty ||
          provider.currentPath == '.') {
        return provider.connection.name;
      }
      return provider.currentPath;
    }

    final allFiles = provider.files;
    final filteredFiles = _searchController.text.isEmpty
        ? allFiles
        : allFiles.where((file) {
            return file.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
          }).toList();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  scrolledUnderElevation: 0,
                  pinned: true,
                  centerTitle: false,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  expandedHeight: 100,
                  leading: IconButton(
                    icon: const Icon(
                      CupertinoIcons.back,
                      color: Colors.white,
                      size: 34,
                    ),
                    onPressed: handleBack,
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 56,
                      bottom: 16,
                    ),
                    title: Hero(
                      tag: 'title_${provider.connection.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          getTitle(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    background: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 20,
                          sigmaY: 20,
                        ),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),

                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: NeonLoader(size: 60)),
                  )
                else if (provider.error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ErrorCard(error: provider.error!),
                      ),
                    ),
                  )
                else if (filteredFiles.isEmpty)
                  EmptyStateCard(
                    icon: _searchController.text.isEmpty
                        ? CupertinoIcons.folder_badge_minus
                        : CupertinoIcons.search,
                    title: _searchController.text.isEmpty
                        ? 'Folder is Empty'
                        : 'No results found',
                    subtitle: _searchController.text.isEmpty
                        ? 'Looks like there\'s nothing here yet.'
                        : 'Try changing your search query.',
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.listHPad(context),
                      vertical: 16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((
                        context,
                        index,
                      ) {
                        final file = filteredFiles[index];

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == filteredFiles.length - 1
                                ? 100
                                : 0,
                          ),
                          child: FadeSlideItem(
                            key: ValueKey(file.path),
                            index: index,
                            child: FileCard(
                              file: file,
                              onTap: () {
                                if (file.isDirectory) {
                                  if (_isSearchActive) {
                                    _toggleSearch();
                                  }
                                  provider.navigateTo(file);
                                } else {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor:
                                        Colors.transparent,
                                    builder: (context) =>
                                        ChangeNotifierProvider.value(
                                          value: provider,
                                          child: FileActionsModal(
                                            file: file,
                                          ),
                                        ),
                                  );
                                }
                              },
                              onLongPress: () {
                                if (file.isDirectory) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor:
                                        Colors.transparent,
                                    builder: (context) =>
                                        ChangeNotifierProvider.value(
                                          value: provider,
                                          child: FolderActionsModal(
                                            folder: file,
                                          ),
                                        ),
                                  );
                                } else {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor:
                                        Colors.transparent,
                                    builder: (context) =>
                                        ChangeNotifierProvider.value(
                                          value: provider,
                                          child: FileActionsModal(
                                            file: file,
                                          ),
                                        ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      }, childCount: filteredFiles.length),
                    ),
                  ),
              ],
            ),

            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.listHPad(context),
                  ),
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final availableWidth = constraints.maxWidth;
                      return StaggeredScaleFade(
                        animation: _fabController,
                        child: SizedBox(
                          height: 56,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(
                                  milliseconds: 200,
                                ),
                                opacity: _isSearchActive ? 0.0 : 1.0,
                                child: IgnorePointer(
                                  ignoring: _isSearchActive,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      NeonCircularButton(
                                        icon:
                                            CupertinoIcons.cloud_upload,
                                        onTap: () =>
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              barrierColor: Colors.black
                                                  .withOpacity(0.5),
                                              builder: (context) =>
                                                  ChangeNotifierProvider
                                                      .value(
                                                        value: provider,
                                                        child: const UploadEntityModal(),
                                                      ),
                                            ),
                                      ),
                                      const SizedBox(width: 16),
                                      NeonCircularButton(
                                        icon: CupertinoIcons.add,
                                        onTap: () =>
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              barrierColor: Colors.black
                                                  .withOpacity(0.5),
                                              builder: (context) =>
                                                  ChangeNotifierProvider
                                                      .value(
                                                        value: provider,
                                                        child: const CreateEntityModal(),
                                                      ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              AnimatedOpacity(
                                duration: const Duration(
                                  milliseconds: 200,
                                ),
                                opacity: _isSearchActive ? 0.0 : 1.0,
                                child: IgnorePointer(
                                  ignoring: _isSearchActive,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: NeonCircularButton(
                                      icon: CupertinoIcons.refresh_bold,
                                      onTap: () => provider.refresh(),
                                    ),
                                  ),
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 400,
                                  ),
                                  curve: Curves.easeOutCubic,
                                  width: _isSearchActive
                                      ? availableWidth
                                      : 56,
                                  height: 56,
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      28,
                                    ),
                                  ),
                                  child: _isSearchActive
                                      ? _buildExpandedSearchBar(
                                          availableWidth,
                                        )
                                      : NeonCircularButton(
                                          icon: CupertinoIcons.search,
                                          onTap: _toggleSearch,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSearchBar(double fullWidth) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: fullWidth,
              height: 60,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: const Icon(
                      CupertinoIcons.search,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: GoogleFonts.poppins(color: Colors.white),
                      cursorColor: Colors.cyanAccent,
                      decoration: InputDecoration(
                        hintText: 'Search files...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white30,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.clear_circled,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_searchController.text.isEmpty) {
                        _toggleSearch();
                      } else {
                        _searchController.clear();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
