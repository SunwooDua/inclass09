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
    _loadFolders();
  }

  void _loadFolders() async {
    final folders = await DatabaseHelper.instance.getFolders();
    setState(() => _folders = folders);
  }

  void _deleteFolder(int folderId) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Folder'),
            content: Text(
              'Are you sure you want to delete this folder? it will delete all the card inside!',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await DatabaseHelper.instance.deleteFolder(folderId);
                  _loadFolders();
                  Navigator.of(context).pop();
                },
                child: Text('Yes'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('No'),
              ),
            ],
          ),
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
              onPressed: () => _deleteFolder(_folders[index]['id']),
            ),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            CardsScreen(folderId: _folders[index]['id']),
                  ),
                ),
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
  bool get _isFolderFull => _cards.length >= 6;
  bool get _isFolderTooEmpty => _cards.length < 3;

  // Predefined card options
  final List<Map<String, String>> _cardOptions = [
    {
      'name': 'Ace of Spades',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/01_of_spades_A.svg/1024px-01_of_spades_A.svg.png',
    },
    {
      'name': 'King of Hearts',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/King_of_hearts_fr.svg/1024px-King_of_hearts_fr.svg.png',
    },
    {
      'name': 'Queen of Diamonds',
      'image_url':
          'https://media.istockphoto.com/id/480325875/photo/playing-cards-queen-of-diamonds.jpg?s=612x612&w=0&k=20&c=zJmT27SyjpI6elVcD2yh4ewcF7QcSs6HiAYMpMiQAHE=',
    },
    {
      'name': 'Jack of Clubs',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/commons/2/2f/Poker-sm-244-Jc.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() async {
    final cards = await DatabaseHelper.instance.getCardsByFolderId(
      widget.folderId,
    );
    setState(() {
      _cards = cards;
    });
  }

  void _addCard(Map<String, String> selectedCard) async {
    if (_isFolderFull) {
      _showErrorDialog('Maximum 6 cards allowed.');
      return;
    }

    final newCard = {
      'name': selectedCard['name'],
      'suit': 'Unknown', // You can modify this if you want to store the suit
      'image_url': selectedCard['image_url'],
      'folder_id': widget.folderId,
    };
    await DatabaseHelper.instance.insertCard(newCard);
    _loadCards();
  }

  void _deleteCard(int cardId) async {
    await DatabaseHelper.instance.deleteCard(cardId);
    _loadCards();

    if (_cards.length - 1 < 3) {
      _showErrorDialog('Minimum 6 cards required.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
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
                      Image.network(
                        _cards[index]['image_url'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image_not_supported, size: 50);
                        },
                      ),
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
            ElevatedButton(
              onPressed: () {
                // Show card selection dialog
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('Select a Card'),
                        content: SingleChildScrollView(
                          child: Column(
                            children:
                                _cardOptions.map((card) {
                                  return ListTile(
                                    title: Text(card['name']!),
                                    leading: Image.network(
                                      card['image_url']!,
                                      width: 30,
                                      height: 30,
                                    ),
                                    onTap: () {
                                      _addCard(card);
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                );
              },
              child: Text('Add Card'),
            ),
        ],
      ),
    );
  }
}
