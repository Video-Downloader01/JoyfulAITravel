import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const JoyfulTravelApp());
}

// 🎨 THEME CONFIGURATION
class AppTheme {
  static const Color primaryOlive = Color(0xFF556B2F);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color cardDark = Color(0xFF1E1E1E);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDark,
        primaryColor: primaryOlive,
        colorScheme: const ColorScheme.dark(
          primary: primaryOlive,
          secondary: accentGold,
          surface: cardDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundDark,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOlive,
            foregroundColor: accentGold,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
}

class JoyfulTravelApp extends StatelessWidget {
  const JoyfulTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joyful AI Travel',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

// 🔐 AUTHENTICATION WRAPPER
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.accentGold)));
        }
        if (snapshot.hasData) {
          return const MainNavigation();
        }
        return const LoginScreen();
      },
    );
  }
}

// 📱 LOGIN SCREEN (PHONE OTP)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = "";
  bool _otpSent = false;

  void verifyPhone() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91${_phoneController.text.trim()}",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification failed')));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void verifyOTP() async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _otpController.text.trim(),
    );
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('wallet').doc(user.uid).get();
        if (!doc.exists) {
          await FirebaseFirestore.instance.collection('wallet').doc(user.uid).set({'coins': 100});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.travel_explore, size: 80, color: AppTheme.accentGold),
            const SizedBox(height: 24),
            Text("Joyful AI Travel", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryOlive)),
            const SizedBox(height: 40),
            if (!_otpSent) ...[
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixText: "+91 ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: verifyPhone, child: const Text("Send OTP")),
            ] else ...[
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: "Enter OTP",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: verifyOTP, child: const Text("Verify & Login")),
            ]
          ],
        ),
      ),
    );
  }
}

// 🧭 MAIN NAVIGATION
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const AIPlannerScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.cardDark,
        selectedItemColor: AppTheme.accentGold,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "AI Planner"),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// 🏠 HOME SCREEN & TRIP PACKAGES
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void bookTrip(BuildContext context, String tripId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('bookings').add({
        'user_id': user.uid,
        'trip_id': tripId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Successful!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Plan your dream trip")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('trips').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
          final trips = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index].data() as Map<String, dynamic>;
              return Card(
                color: AppTheme.cardDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        color: Colors.grey[800],
                        image: trip['image'] != null ? DecorationImage(image: NetworkImage(trip['image']), fit: BoxFit.cover) : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(trip['name'] ?? 'Unknown Trip', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                                const SizedBox(height: 4),
                                Text("₹${trip['price']} • ${trip['days']} Days", style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => bookTrip(context, trips[index].id),
                            child: const Text("Book Now"),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 🤖 AI TRIP PLANNER (Smart Logic Mock)
class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final _destController = TextEditingController();
  final _daysController = TextEditingController();
  final _budgetController = TextEditingController();
  String? _itinerary;

  void generateItinerary() {
    final dest = _destController.text.trim();
    final days = _daysController.text.trim();
    if (dest.isEmpty || days.isEmpty) return;
    
    setState(() {
      _itinerary = "✨ AI Generated Plan for $dest ($days Days)\n\n"
          "Day 1: Arrival & Local Exploration. Check into your hotel and enjoy the local street food.\n"
          "Day 2: Adventure & Sightseeing. Visit the top 3 tourist spots.\n"
          "Day 3: Leisure & Departure. Shopping and return journey.\n\n"
          "Estimated Cost: ₹${_budgetController.text.isNotEmpty ? _budgetController.text : 'Dynamic'}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Trip Planner")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _destController, decoration: const InputDecoration(labelText: "Destination (e.g., Manali, Darjeeling)")),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _daysController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Days"))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _budgetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Budget (₹)"))),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: generateItinerary,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Generate Itinerary"),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 24),
            if (_itinerary != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(child: Text(_itinerary!, style: const TextStyle(height: 1.5))),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// 🌐 COMMUNITY FEED
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Travel Community")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
          final posts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primaryOlive, child: Text(post['user_name']?[0] ?? 'U', style: const TextStyle(color: Colors.white))),
                title: Text(post['user_name'] ?? 'Traveler', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                subtitle: Text(post['text'] ?? ''),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentGold,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          FirebaseFirestore.instance.collection('posts').add({
            'user_name': 'Raman',
            'text': 'Looking forward to our next big trip!',
            'timestamp': FieldValue.serverTimestamp(),
          });
        },
      ),
    );
  }
}

// 👤 USER PROFILE & WALLET
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50, backgroundColor: AppTheme.primaryOlive, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 16),
            Text(user?.phoneNumber ?? "No Phone Number", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('wallet').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                int coins = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  coins = snapshot.data!['coins'] ?? 0;
                }
                return Card(
                  color: AppTheme.accentGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet, color: Colors.black, size: 32),
                    title: const Text("Joyful Coins", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    trailing: Text("$coins", style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Align(alignment: Alignment.centerLeft, child: Text("My Bookings", style: TextStyle(fontSize: 18, color: AppTheme.primaryOlive, fontWeight: FontWeight.bold))),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings').where('user_id', isEqualTo: user?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No bookings yet."));
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final booking = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: const Text("Trip ID booked"),
                        subtitle: Text("Status: ${booking['status']}"),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
