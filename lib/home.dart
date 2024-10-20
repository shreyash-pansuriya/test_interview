import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for SystemChrome
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> filteredList = [];
  int pageSize = 20;
  int currentPage = 1;
  bool isLoading = false;
  bool allDataLoaded = false;
  ScrollController _scrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set the system UI overlay style here
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Set the status bar color to transparent
    ));

    generateUserData();
    loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        loadMore();
      }
    });
  }

  void generateUserData() {
    List<String> cities = ['Mumbai', 'Delhi', 'Chennai', 'Kolkata', 'Bangalore', 'Gujrat', 'Ahmadabad'];
    for (int i = 1; i <= 43; i++) {
      userList.add({
        'name': 'User $i',
        'phone': '90330${i.toString().padLeft(5, '0')}',
        'city': cities[(i - 1) % cities.length],
        'image': 'https://via.placeholder.com/150',
        'rupee': (i % 100),
      });
    }
  }

  void loadInitialData() {
    setState(() {
      filteredList = userList.sublist(0, pageSize);
    });
  }

  void loadMore() {
    if (isLoading || allDataLoaded) return;

    setState(() {
      isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        int nextPage = currentPage + 1;
        int startIndex = currentPage * pageSize;
        int endIndex = nextPage * pageSize;

        if (startIndex < userList.length) {
          if (endIndex > userList.length) {
            endIndex = userList.length;
            allDataLoaded = true;
          }
          filteredList.addAll(userList.sublist(startIndex, endIndex));
          currentPage = nextPage;
        }

        isLoading = false;
      });
    });
  }

  void filterList(String query) {
    List<Map<String, dynamic>> temp = [];
    if (query.isNotEmpty) {
      temp = userList.where((user) {
        return user['name'].toLowerCase().contains(query.toLowerCase()) ||
            user['phone'].contains(query) ||
            user['city'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    } else {
      temp = userList.sublist(0, currentPage * pageSize);
    }

    setState(() {
      filteredList = temp;
    });
  }

  void _showRupeeDialog(int index) {
    TextEditingController rupeeController = TextEditingController(
        text: filteredList[index]['rupee'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Rupee'),
          content: TextField(
            controller: rupeeController,
            decoration: const InputDecoration(labelText: 'Enter new Rupee value'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  filteredList[index]['rupee'] =
                      int.tryParse(rupeeController.text) ?? filteredList[index]['rupee'];
                });
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Confirmation'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // No
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Yes
            child: const Text('Yes'),
          ),
        ],
      ),
    )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Center(
                  child: Text(
                    'User List',
                    style: TextStyle(fontSize: 20), // Adjust the font size if needed
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by name, phone, or city',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  filterList(value);
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filteredList.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredList.length) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  var user = filteredList[index];
                  String rupeeStatus = user['rupee'] > 50 ? "High" : "Low";
                  return Card(
                    child: ListTile(
                      leading: Image.network(user['image']),
                      title: Text(user['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phone: ${user['phone']}'),
                          Text('City: ${user['city']}'),
                          Text('Rupee: ${user['rupee']} ($rupeeStatus)'),
                        ],
                      ),
                      onTap: () => _showRupeeDialog(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
