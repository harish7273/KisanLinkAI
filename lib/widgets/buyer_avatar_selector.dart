import 'package:flutter/material.dart';

class BuyerAvatarSelector
    extends StatelessWidget {
  final String selectedAvatar;

  final ValueChanged<String>
      onSelected;

  const BuyerAvatarSelector({
    super.key,
    required this.selectedAvatar,
    required this.onSelected,
  });

  static const Color orange =
      Color(0xFFFF9800);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children:
          List.generate(
        5,
        (index) {
          final avatar =
              'buyer_${index + 1}';

          final selected =
              selectedAvatar ==
                  avatar;

          return GestureDetector(
            onTap: () {
              onSelected(
                avatar,
              );
            },

            child:
                AnimatedScale(
              scale:
                  selected ? 1.08 : 1.0,

              duration:
                  const Duration(
                milliseconds: 180,
              ),

              child:
                  AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 220,
                ),

                width: 58,
                height: 68,

                padding:
                    const EdgeInsets.all(
                  3,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      selected
                          ? orange.withValues(
                              alpha: .12,
                            )
                          : const Color(
                              0xFF181818,
                            ),

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),

                  border:
                      Border.all(
                    color:
                        selected
                            ? orange
                            : Colors.white12,

                    width:
                        selected ? 2 : 1,
                  ),
                ),

                child:
                    Stack(
                  clipBehavior:
                      Clip.none,

                  children: [
                    Center(
                      child:
                          ClipOval(
                        child:
                            Image.asset(
                          'assets/avatars/$avatar.png',

                          width: 50,
                          height: 50,

                          fit:
                              BoxFit.cover,

                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons
                                  .person_rounded,
                              color:
                                  orange,
                              size: 28,
                            );
                          },
                        ),
                      ),
                    ),

                    if (selected)
                      Positioned(
                        right: -6,
                        top: -7,

                        child:
                            Container(
                          width: 21,
                          height: 21,

                          decoration:
                              BoxDecoration(
                            color:
                                orange,

                            shape:
                                BoxShape
                                    .circle,

                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFF151515,
                              ),
                              width: 2,
                            ),
                          ),

                          child:
                              const Icon(
                            Icons
                                .check_rounded,
                            color:
                                Colors.black,
                            size: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}