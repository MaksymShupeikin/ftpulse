import 'package:flutter/cupertino.dart';
import 'package:ftpulse/core/imports.dart';
import 'package:ftpulse/core/ui/animations/fade_slide_item.dart';
import 'package:ftpulse/presentation/widgets/modals/connection_actions_modal.dart';
import 'package:ftpulse/presentation/widgets/cards/connection_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionsProvider>().loadData();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _fabController.forward();
      });
    });
  }

  Future<void> _onConnectionTap(ServerConnection connection) async {
    _fabController.reverse();

    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => FileBrowserPage(connection: connection),
      ),
    );

    if (mounted) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _fabController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connections = context
        .watch<ConnectionsProvider>()
        .connections;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar.large(
                backgroundColor: Colors.black.withOpacity(0.4),
                scrolledUnderElevation: 0,
                centerTitle: false,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                expandedHeight: 140,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  title: Text(
                    'Connections',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    bottom: 16,
                  ),
                ),
              ),

              if (connections.isEmpty)
                const EmptyStateCard(
                  icon: CupertinoIcons.layers_alt_fill,
                  title: 'No Connections',
                  subtitle:
                      'Add your first FTP or SFTP server to get started.',
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.listHPad(context),
                    vertical: 12,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((
                      context,
                      index,
                    ) {
                      final connection = connections[index];
                      final isLast = index == connections.length - 1;

                      return FadeSlideItem(
                        key: ValueKey(connection.id),
                        index: index,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: isLast ? 100 : 16,
                          ),
                          child: ConnectionCard(
                            connection: connection,
                            onTap: () => _onConnectionTap(connection),
                          ),
                        ),
                      );
                    }, childCount: connections.length),
                  ),
                ),
            ],
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: SafeArea(
                child: StaggeredScaleFade(
                  animation: _fabController,
                  child: NeonCircularButton(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        barrierColor: Colors.black.withOpacity(0.5),
                        builder: (context) =>
                            const ConnectionActionsModal(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }
}
