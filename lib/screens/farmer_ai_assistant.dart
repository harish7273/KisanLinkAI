import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/farmer_ai_service.dart';

class FarmerAiAssistant extends StatefulWidget {
  final String farmerName;

  final String? weatherLocation;

  final double? temperature;

  final String? weatherCondition;

  const FarmerAiAssistant({
    super.key,
    required this.farmerName,
    this.weatherLocation,
    this.temperature,
    this.weatherCondition,
  });

  @override
  State<FarmerAiAssistant> createState() =>
      _FarmerAiAssistantState();
}

class _FarmerAiAssistantState
    extends State<FarmerAiAssistant>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color background =
      Color(0xFF080A09);

  static const Color card =
      Color(0xFF111411);

  static const Color green =
      Color(0xFF65D83F);

  static const Color softGreen =
      Color(0xFF79C96A);

  static const Color darkGreen =
      Color(0xFF102016);

  static const Color secondary =
      Color(0xFFA8ADA8);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  late AnimationController pulseController;

  // ============================================================
  // CHAT
  // ============================================================

  final List<Map<String, dynamic>> messages = [];

  bool isTyping = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    pulseController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    messages.add({
      'isUser': false,
      'message':
          'Vanakkam ${widget.farmerName}! 👋\n\n'
          'I’m KisanAI Assistant. I can help you with '
          'farming, crops, market guidance, weather '
          'and your KisanAI activities.',
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    pulseController.dispose();
    messageController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage(String text) async {
    final message = text.trim();

    if (message.isEmpty || isTyping) {
      return;
    }

    // ----------------------------------------------------------
    // ADD USER MESSAGE
    // ----------------------------------------------------------

    setState(() {
      messages.add({
        'isUser': true,
        'message': message,
      });

      isTyping = true;
    });

    messageController.clear();

    scrollToBottom();

    // ----------------------------------------------------------
    // ASK GEMINI
    // ----------------------------------------------------------

    try {
      final response = await FarmerAiService.ask(
        message,

        farmerName:
            widget.farmerName,

        weatherLocation:
            widget.weatherLocation,

        temperature:
            widget.temperature,

        weatherCondition:
            widget.weatherCondition,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isTyping = false;

        messages.add({
          'isUser': false,
          'message': response,
        });
      });

      scrollToBottom();
    } catch (e) {
      debugPrint(
        'FARMER AI ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isTyping = false;

        messages.add({
          'isUser': false,
          'message':
              '⚠️ I could not connect to KisanAI right now.\n\n'
              'Please check your internet connection '
              'and try again.',
        });
      });

      scrollToBottom();
    }
  }

  // ============================================================
  // QUICK QUESTION
  // ============================================================

  void quickQuestion(String question) {
    sendMessage(question);
  }

  // ============================================================
  // SCROLL TO BOTTOM
  // ============================================================

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!scrollController.hasClients) {
          return;
        }

        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration:
              const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // CLOSE ASSISTANT
  // ============================================================

  void closeAssistant() {
    FocusScope.of(context).unfocus();

    Navigator.pop(context);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height;

    final keyboardHeight =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    final safeBottom =
        MediaQuery.of(context)
            .padding
            .bottom;

    // ----------------------------------------------------------
    // KEYBOARD SAFE HEIGHT
    // ----------------------------------------------------------

    final availableHeight = math.max(
      300.0,
      screenHeight -
          keyboardHeight -
          safeBottom -
          10,
    );

    final assistantHeight = math.min(
      screenHeight * .72,
      availableHeight,
    );

    return Material(
      color: Colors.transparent,

      child: Stack(
        children: [
          // ======================================================
          // BACKDROP
          // ======================================================

          Positioned.fill(
            child: GestureDetector(
              onTap: closeAssistant,

              child: Container(
                color:
                    Colors.black.withOpacity(.70),
              ),
            ),
          ),

          // ======================================================
          // ASSISTANT PANEL
          // ======================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: keyboardHeight,

            child: SafeArea(
              top: false,

              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 180),

                curve: Curves.easeOut,

                height: assistantHeight,

                decoration:
                    const BoxDecoration(
                  color: background,

                  borderRadius:
                      BorderRadius.vertical(
                    top:
                        Radius.circular(28),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black54,

                      blurRadius:
                          30,

                      offset:
                          Offset(0, -8),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    // HEADER
                    buildHeader(),

                    // CHAT
                    Expanded(
                      child:
                          buildChat(),
                    ),

                    // QUICK ACTIONS
                    buildQuickActions(),

                    // INPUT
                    buildInput(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget buildHeader() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        15,
        14,
        15,
      ),

      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,

          colors: [
            Color(0xFF102517),
            Color(0xFF08120B),
          ],
        ),

        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(28),
        ),

        border:
            Border(
          bottom:
              BorderSide(
            color:
                Color(0xFF203125),
          ),
        ),
      ),

      child: Row(
        children: [
          // ======================================================
          // AI ICON
          // ======================================================

          AnimatedBuilder(
            animation:
                pulseController,

            builder:
                (context, child) {
              final scale =
                  1 +
                      pulseController.value *
                          .045;

              return Transform.scale(
                scale: scale,
                child: child,
              );
            },

            child: Container(
              width: 48,
              height: 48,

              decoration:
                  BoxDecoration(
                color: darkGreen,

                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color:
                      softGreen.withOpacity(.45),

                  width: 1.3,
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        green.withOpacity(.08),

                    blurRadius: 12,
                  ),
                ],
              ),

              child:
                  const Icon(
                Icons.smart_toy_rounded,

                color:
                    softGreen,

                size: 26,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ======================================================
          // TITLE
          // ======================================================

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'KisanAI Assistant',

                  style: TextStyle(
                    color:
                        Colors.white,

                    fontSize: 17,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Row(
                  children: [
                    Icon(
                      Icons.circle,

                      color:
                          Color(0xFF5BB94D),

                      size: 6,
                    ),

                    SizedBox(
                      width: 5,
                    ),

                    Text(
                      'AI Farming Companion',

                      style: TextStyle(
                        color:
                            secondary,

                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ======================================================
          // CLOSE
          // ======================================================

          GestureDetector(
            onTap:
                closeAssistant,

            child: Container(
              width: 36,
              height: 36,

              decoration:
                  BoxDecoration(
                color:
                    Colors.white.withOpacity(.06),

                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color:
                      Colors.white.withOpacity(.08),
                ),
              ),

              child:
                  const Icon(
                Icons.close_rounded,

                color:
                    Colors.white70,

                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHAT
  // ============================================================

  Widget buildChat() {
    return ListView.builder(
      controller:
          scrollController,

      padding:
          const EdgeInsets.fromLTRB(
        15,
        17,
        15,
        8,
      ),

      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior
              .onDrag,

      itemCount:
          messages.length +
              (isTyping ? 1 : 0),

      itemBuilder:
          (context, index) {
        // ------------------------------------------------------
        // TYPING INDICATOR
        // ------------------------------------------------------

        if (isTyping &&
            index == messages.length) {
          return buildTypingIndicator();
        }

        final item =
            messages[index];

        final bool isUser =
            item['isUser'] == true;

        final String message =
            item['message']
                .toString();

        return buildMessage(
          message: message,
          isUser: isUser,
        );
      },
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget buildMessage({
    required String message,
    required bool isUser,
  }) {
    return Align(
      alignment:
          isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,

      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  .80,
        ),

        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),

        decoration:
            BoxDecoration(
          color:
              isUser
                  ? const Color(0xFF315A32)
                  : const Color(0xFF141914),

          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(17),

            topRight:
                const Radius.circular(17),

            bottomLeft:
                Radius.circular(
              isUser ? 17 : 4,
            ),

            bottomRight:
                Radius.circular(
              isUser ? 4 : 17,
            ),
          ),

          border:
              Border.all(
            color:
                isUser
                    ? const Color(0xFF47764A)
                    : const Color(0xFF293029),
          ),
        ),

        child: Text(
          message,

          style: const TextStyle(
            color:
                Colors.white,

            fontSize: 12,

            height: 1.45,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TYPING INDICATOR
  // ============================================================

  Widget buildTypingIndicator() {
    return Align(
      alignment:
          Alignment.centerLeft,

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(0xFF141914),

          borderRadius:
              BorderRadius.circular(17),

          border:
              Border.all(
            color:
                const Color(0xFF293029),
          ),
        ),

        child:
            const Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Text(
              'KisanAI is thinking',

              style: TextStyle(
                color:
                    secondary,

                fontSize: 10,
              ),
            ),

            SizedBox(
              width: 8,
            ),

            _TypingDot(),

            SizedBox(
              width: 3,
            ),

            _TypingDot(),

            SizedBox(
              width: 3,
            ),

            _TypingDot(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget buildQuickActions() {
    return Container(
      height: 53,

      decoration:
          const BoxDecoration(
        color:
            Color(0xFF0C100D),
      ),

      child: ListView(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        scrollDirection:
            Axis.horizontal,

        children: [
          // ----------------------------------------------------
          // WEATHER
          // ----------------------------------------------------

          quickChip(
            icon:
                Icons.wb_sunny_outlined,

            title:
                'Weather',

            question:
                'What is the weather like today and what should I consider for farming?',
          ),

          // ----------------------------------------------------
          // MARKET
          // ----------------------------------------------------

          quickChip(
            icon:
                Icons.currency_rupee_rounded,

            title:
                'Market',

            question:
                'Give me guidance about selling my crops and market prices.',
          ),

          // ----------------------------------------------------
          // ORDERS
          // ----------------------------------------------------

          quickChip(
            icon:
                Icons.shopping_bag_outlined,

            title:
                'Orders',

            question:
                'How many orders do I have and what is their current status?',
          ),

          // ----------------------------------------------------
          // FARMING
          // ----------------------------------------------------

          quickChip(
            icon:
                Icons.eco_outlined,

            title:
                'Farming',

            question:
                'Give me some useful farming advice for my crops.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK CHIP
  // ============================================================

  Widget quickChip({
    required IconData icon,
    required String title,
    required String question,
  }) {
    return GestureDetector(
      onTap:
          () => quickQuestion(question),

      child: Container(
        margin:
            const EdgeInsets.only(
          right: 7,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(0xFF121712),

          borderRadius:
              BorderRadius.circular(18),

          border:
              Border.all(
            color:
                const Color(0xFF293129),
          ),
        ),

        child: Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              icon,

              color:
                  const Color(0xFF78B96D),

              size: 15,
            ),

            const SizedBox(
              width: 5,
            ),

            Text(
              title,

              style:
                  const TextStyle(
                color:
                    Colors.white,

                fontSize: 10,

                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget buildInput() {
    final bool hasText =
        messageController.text
            .trim()
            .isNotEmpty;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        13,
        8,
        13,
        12,
      ),

      decoration:
          const BoxDecoration(
        color:
            Color(0xFF0B0E0C),

        border:
            Border(
          top:
              BorderSide(
            color:
                Color(0xFF202620),
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,

        children: [
          // ======================================================
          // TEXT FIELD
          // ======================================================

          Expanded(
            child: Container(
              constraints:
                  const BoxConstraints(
                minHeight: 44,
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFF151A16),

                borderRadius:
                    BorderRadius.circular(22),

                border:
                    Border.all(
                  color:
                      const Color(0xFF293029),
                ),
              ),

              child: TextField(
                controller:
                    messageController,

                minLines: 1,

                maxLines: 3,

                keyboardType:
                    TextInputType.multiline,

                textInputAction:
                    TextInputAction.newline,

                style:
                    const TextStyle(
                  color:
                      Colors.white,

                  fontSize: 12,
                ),

                onChanged:
                    (_) {
                  setState(() {});
                },

                decoration:
                    const InputDecoration(
                  hintText:
                      'Ask KisanAI anything...',

                  hintStyle:
                      TextStyle(
                    color:
                        Color(0xFF666D67),

                    fontSize: 11,
                  ),

                  border:
                      InputBorder.none,

                  isDense:
                      true,

                  contentPadding:
                      EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          // ======================================================
          // SEND BUTTON
          // ======================================================

          GestureDetector(
            onTap:
                hasText && !isTyping
                    ? () {
                        sendMessage(
                          messageController.text,
                        );
                      }
                    : null,

            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),

              width: 44,
              height: 44,

              decoration:
                  BoxDecoration(
                color:
                    hasText && !isTyping
                        ? const Color(
                            0xFF4D9845,
                          )
                        : const Color(
                            0xFF263029,
                          ),

                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color:
                      hasText && !isTyping
                          ? const Color(
                              0xFF6FB866,
                            )
                          : const Color(
                              0xFF354037,
                            ),
                ),
              ),

              child:
                  Icon(
                Icons.arrow_upward_rounded,

                color:
                    hasText && !isTyping
                        ? Colors.white
                        : const Color(
                            0xFF69736B,
                          ),

                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// TYPING DOT
// ================================================================

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 5,
      height: 5,

      decoration:
          const BoxDecoration(
        color:
            Color(0xFF79C96A),

        shape:
            BoxShape.circle,
      ),
    );
  }
}