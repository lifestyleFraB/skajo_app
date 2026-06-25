import 'package:flutter/material.dart';

void main() {
  runApp(const SkajoApp());
}

class SkajoApp extends StatelessWidget {
  const SkajoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skajo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal[700],
          secondary: Colors.amber[600],
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const SkajoBlockDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Player {
  String name;
  Player({required this.name});
}

class SkajoBlockDashboard extends StatefulWidget {
  const SkajoBlockDashboard({super.key});

  @override
  State<SkajoBlockDashboard> createState() => _SkajoBlockDashboardState();
}

class _SkajoBlockDashboardState extends State<SkajoBlockDashboard> {
  final List<Player> _players = [];

  // Feste Matrix für 10 Runden und bis zu 5 Spieler (Initialisiert mit null = noch nicht gespielt)
  final List<List<int?>> _fixedRounds = List.generate(
    10,
    (_) => List.generate(5, (_) => null),
  );

  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _scoreControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  // Findet heraus, wer in der aktuell als nächstes offenen Runde der Geber ist
  int get _currentDealerIndex {
    if (_players.isEmpty) return 0;

    // Suche die erste Runde, in der noch kein Ergebnis eingetragen wurde
    int nextRoundIndex = 0;
    for (int i = 0; i < 10; i++) {
      if (_fixedRounds[i][0] == null) {
        nextRoundIndex = i;
        break;
      }
    }
    return nextRoundIndex % _players.length;
  }

  void _addPlayer() {
    if (_players.length >= 5) {
      _showSnackBar('Maximale Spieleranzahl (5) erreicht!');
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Bitte einen Namen eingeben.');
      return;
    }
    if (_players.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      _showSnackBar('Spieler existiert bereits!');
      return;
    }

    setState(() {
      _players.add(Player(name: name));
      _nameController.clear();

      // Für den neuen Spieler in allen 10 Runden den Wert auf 0 setzen, statt null
      int playerIndex = _players.length - 1;
      for (int i = 0; i < 10; i++) {
        _fixedRounds[i][playerIndex] = 0;
      }
    });
    Navigator.of(context).pop();
  }

  void _saveRoundScores(int roundIndex) {
    setState(() {
      for (int i = 0; i < _players.length; i++) {
        final text = _scoreControllers[i].text.trim();
        // Erlaubt normale Tastatureingaben auf PC und Smartphone gleichermaßen
        _fixedRounds[roundIndex][i] = int.tryParse(text) ?? 0;
      }
    });
    Navigator.of(context).pop();
  }

  int _getPlayerTotalScore(int playerIndex) {
    int total = 0;
    for (int i = 0; i < 10; i++) {
      total += (_fixedRounds[i][playerIndex] ?? 0);
    }
    return total;
  }

  void _resetScores() {
    setState(() {
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 5; j++) {
          _fixedRounds[i][j] = j < _players.length ? 0 : null;
        }
      }
    });
  }

  void _clearAll() {
    setState(() {
      _players.clear();
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 5; j++) {
          _fixedRounds[i][j] = null;
        }
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openAddPlayerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Spieler hinzufügen'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Name des Spielers',
            prefixIcon: Icon(Icons.person),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: _addPlayer,
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  // Öffnet den Dialog für eine ganz bestimmte Zeile (Runde)
  void _openEditRoundDialog(int roundIndex) {
    if (_players.isEmpty) return;

    for (int i = 0; i < _players.length; i++) {
      final currentPoints = _fixedRounds[roundIndex][i];
      _scoreControllers[i].text = currentPoints == 0
          ? ''
          : (currentPoints?.toString() ?? '');
    }

    final dealerIndex = roundIndex % _players.length;
    final dealerName = _players[dealerIndex].name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spiel #${roundIndex + 1} eintragen'),
            const SizedBox(height: 4),
            Text(
              '🃏 Geber: $dealerName',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_players.length, (index) {
              final isDealer = (index == dealerIndex);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _scoreControllers[index],
                  // TextInputType.text verhindert Tastatur-Sperren auf Desktop/Web!
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText:
                        _players[index].name + (isDealer ? ' (Geber 🃏)' : ''),
                    border: const OutlineInputBorder(),
                    prefixIcon: isDealer
                        ? Icon(Icons.style, color: Colors.amber[700])
                        : const Icon(Icons.edit),
                    filled: isDealer,
                    fillColor: isDealer ? Colors.amber.withOpacity(0.05) : null,
                    hintText: '0',
                  ),
                ),
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => _saveRoundScores(roundIndex),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Skajo 10er-Block',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_players.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Block leeren',
              onPressed: () => _showConfirmDialog(
                'Punkte nullen?',
                'Alle 10 Runden werden auf 0 gesetzt.',
                _resetScores,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Alles löschen',
              onPressed: () => _showConfirmDialog(
                'Komplett zurücksetzen?',
                'Spieler und Ergebnisse werden gelöscht.',
                _clearAll,
              ),
            ),
          ],
        ],
      ),
      body: _players.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.border_color_outlined,
                    size: 90,
                    color: Colors.teal.withOpacity(0.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Der Block ist leer.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Füge bis zu 5 Spieler hinzu, um das Spiel zu starten!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // --- SEKTION 1: GESAMTSTAND ---
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 8.0,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'GESAMTSUMME (10 RUNDEN)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800],
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(_players.length, (index) {
                              final totalScore = _getPlayerTotalScore(index);
                              final isNextDealer =
                                  (index == _currentDealerIndex);

                              return Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: isNextDealer
                                      ? BoxDecoration(
                                          border: Border.all(
                                            color: Colors.amber.shade400,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.amber.shade50
                                              .withOpacity(0.5),
                                        )
                                      : null,
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _players[index].name,
                                              style: TextStyle(
                                                fontWeight: isNextDealer
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 15,
                                                color: isNextDealer
                                                    ? Colors.amber[900]
                                                    : Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isNextDealer) ...[
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.style,
                                              size: 14,
                                              color: Colors.amber[700],
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$totalScore',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: totalScore >= 0
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- SEKTION 2: DER ANZEIGENDE 10er-BLOCK ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Colors.teal[50],
                              ),
                              dataRowMinHeight: 48,
                              horizontalMargin: 16,
                              columnSpacing: 28,
                              showCheckboxColumn: false,
                              columns: [
                                const DataColumn(
                                  label: Text(
                                    'Spiel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ),
                                ..._players.map(
                                  (player) => DataColumn(
                                    label: Text(
                                      player.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              rows: List.generate(10, (roundIndex) {
                                final dealerOfThisRound =
                                    roundIndex % _players.length;

                                return DataRow(
                                  onSelectChanged: (_) => _openEditRoundDialog(
                                    roundIndex,
                                  ), // Klick auf Zeile öffnet den Eintragungsmodus
                                  cells: [
                                    DataCell(
                                      Text(
                                        'Spiel #${roundIndex + 1}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ...List.generate(_players.length, (
                                      playerIndex,
                                    ) {
                                      final val =
                                          _fixedRounds[roundIndex][playerIndex] ??
                                          0;
                                      final wasDealer =
                                          (playerIndex == dealerOfThisRound);

                                      return DataCell(
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: wasDealer
                                              ? BoxDecoration(
                                                  color: Colors.amber
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                )
                                              : null,
                                          child: Text(
                                            '$val' + (wasDealer ? ' 🃏' : ''),
                                            style: TextStyle(
                                              fontWeight: wasDealer
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: val == 0
                                                  ? Colors.grey
                                                  : (val > 0
                                                        ? Colors.black87
                                                        : Colors.red[700]),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              if (_players.length < 5)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openAddPlayerDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Spieler hinzufügen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[900],
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
