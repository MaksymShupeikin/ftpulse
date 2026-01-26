import 'package:ftpulse/core/imports.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';

class ConnectionActionsModal extends StatefulWidget {
  final ServerConnection? connection;

  const ConnectionActionsModal({super.key, this.connection});

  @override
  State<ConnectionActionsModal> createState() =>
      _ConnectionActionsModalState();
}

class _ConnectionActionsModalState
    extends State<ConnectionActionsModal> {
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _userController;
  late TextEditingController _passController;
  late bool _localIsSftp;
  late bool _useBiometrics;

  bool _isPasswordVisible = false;

  bool get isEditMode => widget.connection != null;

  @override
  void initState() {
    super.initState();

    final provider = context.read<ConnectionsProvider>();

    if (isEditMode) {
      final conn = widget.connection!;
      _nameController = TextEditingController(text: conn.name);
      _hostController = TextEditingController(text: conn.host);
      _portController = TextEditingController(
        text: conn.port.toString(),
      );
      _userController = TextEditingController(text: conn.username);
      _passController = TextEditingController(text: conn.password);
      _localIsSftp = conn.isSftp;
      _useBiometrics = conn.useBiometrics;
    } else {
      final draft = provider.draft;
      _nameController = TextEditingController(text: draft.name);
      _hostController = TextEditingController(text: draft.host);
      _portController = TextEditingController(
        text: draft.port.toString(),
      );
      _userController = TextEditingController(text: draft.username);
      _passController = TextEditingController(text: draft.password);
      _localIsSftp = draft.isSftp;
      _useBiometrics = draft.useBiometrics;

      _nameController.addListener(
        () => provider.updateDraft(name: _nameController.text),
      );
      _hostController.addListener(
        () => provider.updateDraft(host: _hostController.text),
      );
      _portController.addListener(
        () => provider.updateDraft(port: _portController.text),
      );
      _userController.addListener(
        () => provider.updateDraft(username: _userController.text),
      );
      _passController.addListener(
        () => provider.updateDraft(password: _passController.text),
      );
    }
  }

  Future<void> _onBiometricChanged(bool value) async {
    if (isEditMode && _useBiometrics && !value) {
      final authenticated = await BiometricService.authenticate();

      if (authenticated) {
        setState(() => _useBiometrics = false);
      } else {}
    } else {
      setState(() => _useBiometrics = value);

      if (!isEditMode) {
        context.read<ConnectionsProvider>().updateDraft(
          useBiometrics: value,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionsProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1A).withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              bottomInset + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Text(
                    isEditMode ? 'Edit Connection' : 'New Connection',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  NeonToggleSwitch(
                    options: ['SFTP', 'FTP'],
                    selectedIndex: _localIsSftp ? 0 : 1,
                    onChanged: (index) {
                      final isSftp = index == 0;
                      setState(() {
                        _localIsSftp = isSftp;
                        final currentPort = _portController.text;
                        if (isSftp && currentPort == '21') {
                          _portController.text = '22';
                        } else if (!isSftp && currentPort == '22') {
                          _portController.text = '21';
                        }
                      });
                      if (!isEditMode) {
                        provider.updateDraft(isSftp: isSftp);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  GlassTextField(
                    controller: _nameController,
                    hint: 'Connection Name (e.g. Work)',
                    icon: CupertinoIcons.tag,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: GlassTextField(
                          controller: _hostController,
                          hint: 'Host / IP Address',
                          icon: CupertinoIcons.globe,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: GlassTextField(
                          controller: _portController,
                          hint: 'Port',
                          icon: CupertinoIcons.number,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GlassTextField(
                    controller: _userController,
                    hint: 'Username',
                    icon: CupertinoIcons.person,
                  ),
                  const SizedBox(height: 16),

                  GlassTextField(
                    controller: _passController,
                    hint: 'Password',
                    icon: CupertinoIcons.lock,
                    isPassword: !_isPasswordVisible,
                    changeSuffixIcon: () => setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    }),
                  ),

                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.02),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.lock_shield,
                              color: Colors.white.withOpacity(0.4),
                              size: 20,
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Text(
                                'Protect with FaceID',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(
                                    0.8,
                                  ),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            CupertinoSwitch(
                              value: _useBiometrics,
                              activeColor: const Color(0xFF00C2FF),
                              trackColor: Colors.white.withOpacity(
                                0.1,
                              ),
                              onChanged: _onBiometricChanged,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (provider.connectionError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ErrorCard(
                        error: provider.connectionError!,
                      ),
                    ),

                  NeonButton(
                    text: isEditMode
                        ? 'Save Changes'
                        : 'Connect & Save',
                    isLoading: provider.isTestingConnection,
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      bool success = false;

                      if (isEditMode) {
                        final updatedConnection = widget.connection!
                            .copyWith(
                              name: _nameController.text,
                              host: _hostController.text,
                              port:
                                  int.tryParse(
                                    _portController.text,
                                  ) ??
                                  21,
                              username: _userController.text,
                              password: _passController.text,
                              isSftp: _localIsSftp,
                              useBiometrics: _useBiometrics,
                            );
                        success = await provider.updateConnection(
                          updatedConnection,
                        );
                      } else {
                        provider.updateDraft(
                          useBiometrics: _useBiometrics,
                        );
                        success = await provider.createFromDraft();
                      }

                      if (success && context.mounted) {
                        Navigator.pop(context);
                        if (!isEditMode) {
                          final newConn = provider.connections.last;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FileBrowserPage(
                                connection: newConn,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),

                  if (isEditMode) ...[
                    const SizedBox(height: 16),
                    NeonButton(
                      text: 'Delete Connection',
                      isRed: true,
                      onTap: () {
                        if (provider.isTestingConnection) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => DeleteDialog(
                            title: 'Delete Connection?',
                            message:
                                'Are you sure you want to delete "${widget.connection?.name}"? This cannot be undone.',
                            confirmText: 'Delete',
                            onConfirm: () async {
                              await provider.deleteConnection(
                                widget.connection!.id,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ToastUtils.show(
                                  context,
                                  'Connection deleted',
                                  isError: true,
                                );
                              }
                              return true;
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }
}
