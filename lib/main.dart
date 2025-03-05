import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FoldersScreen(),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Map<String, dynamic>> _folders = [];

  @override
  void initState() {
    super.initState();
    _addTestFolder(); // Add test folder to ensure there is data
    _loadFolders();
  }

  // Load folders from the database
  void _loadFolders() async {
    final folders =
        await DatabaseHelper.instance.getFolders(); // Use instance here
    print('Loaded folders: $folders'); // Debugging print statement
    setState(() {
      _folders = folders;
    });
  }

  // Insert a test folder
  void _addTestFolder() async {
    final newFolder = {
      'name': 'Test Folder',
      'timestamp': DateTime.now().toString(),
    };
    await DatabaseHelper.instance.insertFolder(newFolder); // Use instance here

    // Now, add some test cards for that folder
    final folderId = 1; // Assuming the first folder is our "Test Folder"
    await DatabaseHelper.instance.insertCard({
      'name': 'Ace of Spades',
      'suit': 'Spades',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/01_of_spades_A.svg/1024px-01_of_spades_A.svg.png',
      'folder_id': folderId,
    });
    await DatabaseHelper.instance.insertCard({
      'name': 'King of Hearts',
      'suit': 'Hearts',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/King_of_hearts_fr.svg/1024px-King_of_hearts_fr.svg.png',
      'folder_id': folderId,
    });

    _loadFolders(); // Reload folders after insertion
  }

  // Delete a folder
  void _deleteFolder(int folderId) async {
    // Confirm the folder deletion
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Folder'),
          content: Text(
            'Are you sure you want to delete this folder and all its cards?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.deleteFolder(
                  folderId,
                ); // Delete folder and associated cards
                _loadFolders(); // Reload folders after deletion
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Card Organizer')),
      body: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_folders[index]['name']),
            subtitle: Text('Tap to view cards'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _deleteFolder(_folders[index]['id']); // Delete the folder
              },
            ),
            onTap: () {
              // Navigate to the Cards screen for that folder
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CardsScreen(folderId: _folders[index]['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final int folderId;

  CardsScreen({required this.folderId});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isFolderFull = false;
  bool _isFolderTooEmpty = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  // Load cards for the selected folder
  void _loadCards() async {
    final cards = await DatabaseHelper.instance.getCardsByFolderId(
      widget.folderId,
    ); // Use instance here
    print(
      'Loaded cards for folder ${widget.folderId}: $cards',
    ); // Debugging print statement
    setState(() {
      _cards = cards;
      _isFolderFull = _cards.length >= 6;
      _isFolderTooEmpty = _cards.length < 3;
    });
  }

  // Add card to folder
  void _addCard() async {
    final cardCount = _cards.length;
    if (cardCount >= 6) {
      // Folder is full, show an error dialog
      showDialog(
        context: context,
        builder:
            (BuildContext context) => AlertDialog(
              title: Text('Error'),
              content: Text('This folder can only hold 6 cards.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    // Add card logic here (e.g., show dialog to enter card name)
    final newCard = {
      'name': 'New Card', // Example card details
      'suit': 'Hearts',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/Jack_of_diamonds_fr.svg/1024px-Jack_of_diamonds_fr.svg.png', // Add a sample URL or use a placeholder image
      'folder_id': widget.folderId,
    };
    await DatabaseHelper.instance.insertCard(newCard); // Use instance here
    _loadCards(); // Reload the cards
  }

  // Delete card from folder
  void _deleteCard(int cardId) async {
    final cardCount = _cards.length;
    await DatabaseHelper.instance.deleteCard(cardId); // Use instance here
    _loadCards(); // Reload the cards

    // Ensure folder has at least 3 cards
    if (cardCount - 1 < 3) {
      showDialog(
        context: context,
        builder:
            (BuildContext context) => AlertDialog(
              title: Text('Warning'),
              content: Text('You need at least 3 cards in this folder.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cards in Folder')),
      body: Column(
        children: [
          if (_isFolderTooEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'You need at least 3 cards in this folder.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Column(
                    children: [
                      _cards[index]['image_url'].isNotEmpty
                          ? Image.network(
                            _cards[index]['image_url'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported,
                                size: 50,
                              ); // Fallback if image is not loaded
                            },
                          )
                          : Icon(
                            Icons.image_not_supported,
                            size: 50,
                          ), // Fallback for missing images
                      Text(_cards[index]['name']),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteCard(_cards[index]['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (!_isFolderFull)
            ElevatedButton(onPressed: _addCard, child: Text('Add Card')),
        ],
      ),
    );
  }
}
