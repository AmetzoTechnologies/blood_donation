import 'package:blood_donation/Constant/Constant.dart';
import 'package:blood_donation/Controller/NavController/BottomNavController.dart';
import 'package:blood_donation/Screens/FindDonorPage/FindDonorPage.dart';
import 'package:blood_donation/Screens/ProfilePage/ProfilePage.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _donormateRed = Color(0xFFE71921);
const Color _donormateCyan = Color(0xFF11C0CC);
const Color _softCyan = Color(0xFFE9FBFC);
const Color _supportMint = Color(0xFFEAFBF4);
const Color _avatarGreen = Color(0xFF009D8F);

const String _supportPhoneDisplay = '+91 95393 94545';
const String _supportPhoneDial = '+919539394545';
const String _supportEmail = 'shibilparamban@gmail.com';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<String> _bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];

  @override
  Widget build(BuildContext context) {
    final user = userModel?.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.whiteColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HomeHero(
              name: user.name ?? "User",
              bloodGroup: user.bloodGroup ?? "-",
              profilePic: user.profilePic,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 108),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatusBanner(isDonor: user.isDonor ?? false),
                const SizedBox(height: 22),
                const _SectionTitle(
                  title: "Find Donors",
                  icon: Icons.water_drop,
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bloodGroups.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final group = _bloodGroups[index];
                    return _BloodGroupTile(
                      group: group,
                      onTap: () =>
                          Get.to(() => FindDonorsPage(bloodGroup: group)),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: "Support",
                  icon: Icons.volunteer_activism,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SupportTile(
                        icon: Icons.phone_outlined,
                        title: "Contact us",
                        subtitle: _supportPhoneDisplay,
                        iconBgColor: _softCyan,
                        onTap: () => _launchExternalUri(
                          Uri(scheme: 'tel', path: _supportPhoneDial),
                          errorMessage: 'Could not open dialer',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SupportTile(
                        icon: Icons.email_outlined,
                        title: "Support us",
                        subtitle: _supportEmail,
                        iconBgColor: _supportMint,
                        onTap: () => _launchExternalUri(
                          Uri(
                            scheme: 'mailto',
                            path: _supportEmail,
                          ),
                          errorMessage: 'Could not open email app',
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.name,
    required this.bloodGroup,
    required this.profilePic,
  });

  final String name;
  final String bloodGroup;
  final String? profilePic;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 326,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HeroBackgroundPainter()),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: const [
                    Align(alignment: Alignment.topLeft, child: _HeroBrand()),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 36,
            top: 116,
            child: _HeroDrop(bloodGroup: bloodGroup),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            child: _ProfileCard(name: name, profilePic: profilePic),
          ),
        ],
      ),
    );
  }
}

class _HeroBrand extends StatelessWidget {
  const _HeroBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          "assets/images/donormate_logo.png",
          width: 112,
          height: 112,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 1),
        Text(
          "MYL MANHAPPATTA",
          style: TextStyle(
            color: _donormateCyan,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        // RichText(
        //   text: const TextSpan(
        //     children: [
        //       TextSpan(
        //         text: "Donor",
        //         style: TextStyle(
        //           color: _donormateRed,
        //           fontSize: 28,
        //           fontWeight: FontWeight.w900,
        //         ),
        //       ),
        //       TextSpan(
        //         text: "mate",
        //         style: TextStyle(
        //           color: _donormateCyan,
        //           fontSize: 28,
        //           fontWeight: FontWeight.w900,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // const SizedBox(height: 1),
        // SizedBox(
        //   width: 156,
        //   height: 15,
        //   child: CustomPaint(painter: _BrandEcgPainter()),
        // ),
        const SizedBox(height: 1),
      ],
    );
  }
}

class _BrandEcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * .50;
    final paint = Paint()
      ..color = _donormateRed
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, y)
      ..lineTo(size.width * .44, y)
      ..lineTo(size.width * .50, size.height * .08)
      ..lineTo(size.width * .56, size.height * .86)
      ..lineTo(size.width * .61, size.height * .22)
      ..lineTo(size.width * .66, y)
      ..lineTo(size.width, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroDrop extends StatelessWidget {
  const _HeroDrop({required this.bloodGroup});

  final String bloodGroup;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      width: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _DropPainter())),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                bloodGroup,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dropPath = _dropPath(size);
    canvas.drawShadow(
      dropPath.shift(const Offset(0, 8)),
      _donormateRed.withValues(alpha: .30),
      14,
      false,
    );

    final dropPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF2733), Color(0xFFC9131C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawPath(dropPath, dropPaint);

    final shadePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.black.withValues(alpha: .18), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .66, size.height * .70),
              radius: size.width * .48,
            ),
          );
    canvas.drawPath(dropPath, shadePaint);

    final highlight = Path()
      ..moveTo(size.width * .39, size.height * .34)
      ..cubicTo(
        size.width * .27,
        size.height * .50,
        size.width * .29,
        size.height * .68,
        size.width * .43,
        size.height * .77,
      )
      ..cubicTo(
        size.width * .33,
        size.height * .62,
        size.width * .36,
        size.height * .48,
        size.width * .47,
        size.height * .34,
      );
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: .24)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlight, highlightPaint);

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(dropPath, rimPaint);
  }

  Path _dropPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * .50, h * .02)
      ..cubicTo(w * .86, h * .36, w * .96, h * .55, w * .94, h * .69)
      ..cubicTo(w * .91, h * .91, w * .73, h * .99, w * .50, h * .99)
      ..cubicTo(w * .27, h * .99, w * .09, h * .91, w * .06, h * .69)
      ..cubicTo(w * .04, h * .55, w * .14, h * .36, w * .50, h * .02)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.profilePic});

  final String name;
  final String? profilePic;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42E8F0), Color(0xFF0097A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _donormateCyan.withValues(alpha: .35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Row(
            children: [
              _ProfileAvatar(name: name, profilePic: profilePic),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, required this.profilePic});

  final String name;
  final String? profilePic;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _profileImage(profilePic);
    final initial = name.trim().isEmpty ? "U" : name.trim()[0].toUpperCase();

    return Container(
      height: 66,
      width: 66,
      decoration: const BoxDecoration(
        color: _avatarGreen,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isDonor});

  final bool isDonor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .07),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (Get.isRegistered<BottomNavController>()) {
              Get.find<BottomNavController>().changePage(1);
            } else {
              Get.to(() => ProfilePage());
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: const BoxDecoration(
                    color: _softCyan,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDonor ? Icons.verified_outlined : Icons.info_outline_rounded,
                    color: _donormateCyan,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isDonor
                        ? "Your donor profile is\navailable for requests"
                        : "Turn on donor availability\nfrom your profile",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: _donormateCyan, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _donormateCyan, size: 24),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: _donormateCyan.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _BloodGroupTile extends StatelessWidget {
  const _BloodGroupTile({required this.group, required this.onTap});

  final String group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tileSize = constraints.biggest.shortestSide;
              final dropHeight = tileSize * 2;
              final dropWidth = tileSize * 0.8;

              return Center(
                child: SizedBox(
                  height: dropHeight,
                  width: dropWidth,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          "assets/images/blood_drop.png",
                          fit: BoxFit.fill,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: tileSize * .08),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            group,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: tileSize * .24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              // shadows: [
                              //   Shadow(
                              //     color: Colors.black.withValues(alpha: .25),
                              //     blurRadius: 4,
                              //     offset: const Offset(0, 1),
                              //   ),
                              // ],
                            ),
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
    );
  }
}

Future<void> _launchExternalUri(
  Uri uri, {
  required String errorMessage,
}) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    Get.snackbar('Error', errorMessage);
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .07),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _donormateCyan, size: 25),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [_softCyan, Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final wavePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color.fromARGB(255, 116, 234, 242),
          Color.fromARGB(255, 198, 243, 244),
          Colors.white,
        ],
        stops: [0, .48, 1],
        begin: Alignment.topRight,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    final wavePath = Path()
      ..moveTo(size.width, size.height * .24)
      ..cubicTo(
        size.width * .86,
        size.height * .30,
        size.width * .80,
        size.height * .35,
        size.width * .68,
        size.height * .36,
      )
      ..cubicTo(
        size.width * .55,
        size.height * .37,
        size.width * .48,
        size.height * .54,
        size.width * .34,
        size.height * .66,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * .24)
      ..close();
    canvas.drawPath(wavePath, wavePaint);

    final linePaint = Paint()
      ..color = _donormateCyan.withValues(alpha: .28)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final baseY = size.height * .62;
    final ecgPath = Path()
      ..moveTo(size.width * .50, baseY)
      ..lineTo(size.width * .59, baseY)
      ..lineTo(size.width * .61, baseY - 9)
      ..lineTo(size.width * .63, baseY + 9)
      ..lineTo(size.width * .66, baseY)
      ..lineTo(size.width * .70, baseY)
      ..lineTo(size.width * .72, baseY - 38)
      ..lineTo(size.width * .74, baseY + 14)
      ..lineTo(size.width * .77, baseY)
      ..lineTo(size.width * .82, baseY)
      ..lineTo(size.width * .84, baseY - 8)
      ..lineTo(size.width * .86, baseY)
      ..lineTo(size.width, baseY);
    canvas.drawPath(ecgPath, linePaint);

    _drawHeart(canvas, Offset(size.width * .55, size.height * .34), 11);
    _drawHeart(canvas, Offset(size.width * .69, size.height * .50), 8);
  }

  void _drawHeart(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: .24)
      ..style = PaintingStyle.fill;

    final path = Path();

    final x = center.dx;
    final y = center.dy;

    // Start at the bottom tip
    path.moveTo(x, y + size);

    // Left curve (left lobe)
    path.cubicTo(
      x - size * 1.4,
      y + size * 0.3, // control 1: reduced X (was 2.0)
      x - size * 1.4,
      y - size * 1.2, // control 2: increased Y lift (was 0.8)
      x,
      y - size * 0.4, // top-center dip
    );

    // Right curve (right lobe)
    path.cubicTo(
      x + size * 1.4,
      y - size * 1.2, // mirrors left
      x + size * 1.4,
      y + size * 0.3, // mirrors left
      x,
      y + size, // bottom tip
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String? _profileImage(String? profilePic) {
  if (profilePic == null || profilePic.isEmpty) {
    return null;
  }
  if (profilePic.startsWith("http://") || profilePic.startsWith("https://")) {
    return profilePic;
  }
  return "$baseUrl$profilePic";
}
