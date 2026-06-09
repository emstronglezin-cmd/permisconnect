import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class QuizSessionScreen extends StatefulWidget {
  final String categoryId;

  const QuizSessionScreen({super.key, required this.categoryId});

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswerId;
  bool _isAnswered = false;
  bool _isLoading = true;
  int _correctAnswers = 0;
  int _timeLeft = 30;
  late Timer _timer;
  late AnimationController _progressAnim;
  late AnimationController _bounceAnim;

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await rootBundle.loadString('assets/data/quiz_data.json');
      final json = jsonDecode(data);
      List<Map<String, dynamic>> allQuestions =
          List<Map<String, dynamic>>.from(json['questions']);

      if (widget.categoryId != 'exam') {
        allQuestions = allQuestions
            .where((q) => q['category_id'] == widget.categoryId)
            .toList();
      }

      // Mélanger et limiter
      allQuestions.shuffle();
      final limit = widget.categoryId == 'exam' ? 10 : 5;
      setState(() {
        _questions = allQuestions.take(limit).toList();
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _questions = _fallbackQuestions;
        _isLoading = false;
      });
      _startTimer();
    }
  }

  final List<Map<String, dynamic>> _fallbackQuestions = [
    {
      'id': 'q_demo',
      'question_text': 'Quelle est la vitesse maximale en agglomération ?',
      'answers': [
        {'id': 'a1', 'text': '30 km/h', 'is_correct': false, 'order': 0},
        {'id': 'a2', 'text': '50 km/h', 'is_correct': true, 'order': 1},
        {'id': 'a3', 'text': '70 km/h', 'is_correct': false, 'order': 2},
        {'id': 'a4', 'text': '90 km/h', 'is_correct': false, 'order': 3},
      ],
      'explanation': 'La vitesse maximale en agglomération est de 50 km/h.',
      'difficulty': 'EASY',
    },
  ];

  void _startTimer() {
    _timeLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          t.cancel();
          if (!_isAnswered) _timeExpired();
        }
      });
    });
  }

  void _timeExpired() {
    setState(() {
      _isAnswered = true;
    });
  }

  void _selectAnswer(String answerId, bool isCorrect) {
    if (_isAnswered) return;
    _timer.cancel();
    if (isCorrect) _correctAnswers++;
    setState(() {
      _selectedAnswerId = answerId;
      _isAnswered = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerId = null;
        _isAnswered = false;
        _timeLeft = 30;
      });
      _startTimer();
    } else {
      _timer.cancel();
      context.pushReplacement('/student/quiz/result', extra: {
        'score': ((_correctAnswers / _questions.length) * 100).round(),
        'totalQuestions': _questions.length,
        'correctAnswers': _correctAnswers,
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressAnim.dispose();
    _bounceAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E65C5))),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: const Color(0xFF1E65C5),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Aucune question disponible')),
      );
    }

    final question = _questions[_currentIndex];
    final answers = List<Map<String, dynamic>>.from(question['answers'])
      ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    final correctId = answers.firstWhere((a) => a['is_correct'] == true)['id'];
    final timerProgress = _timeLeft / 30;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E65C5),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _timer.cancel();
            context.pop();
          },
        ),
        title: Text(
          widget.categoryId == 'exam' ? 'Examen Blanc' : 'Quiz',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          Container(
            color: const Color(0xFF1E65C5),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentIndex + 1) / _questions.length,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7F27)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Timer
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _timeLeft <= 10
                                ? const Color(0xFFE74C3C)
                                : Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 44, height: 44,
                              child: CircularProgressIndicator(
                                value: timerProgress,
                                strokeWidth: 3,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _timeLeft <= 10
                                      ? const Color(0xFFE74C3C)
                                      : Colors.white,
                                ),
                              ),
                            ),
                            Text('$_timeLeft',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _timeLeft <= 10
                                        ? const Color(0xFFFFCDD2)
                                        : Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E65C5).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Question ${_currentIndex + 1}',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E65C5)),
                              ),
                            ),
                            const Spacer(),
                            _buildDifficultyBadge(question['difficulty'] ?? 'EASY'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          question['question_text'] ?? '',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Réponses
                  ...List.generate(answers.length, (i) {
                    final answer = answers[i];
                    final id = answer['id'] as String;
                    final isSelected = _selectedAnswerId == id;
                    final isCorrect = id == correctId;

                    Color cardColor = Colors.white;
                    Color borderColor = const Color(0xFFE5E7EB);
                    Color textColor = const Color(0xFF1A1A2E);
                    Widget? trailingIcon;

                    if (_isAnswered) {
                      if (isCorrect) {
                        cardColor = const Color(0xFF27AE60).withValues(alpha: 0.08);
                        borderColor = const Color(0xFF27AE60);
                        textColor = const Color(0xFF1B7E41);
                        trailingIcon = const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF27AE60), size: 22);
                      } else if (isSelected && !isCorrect) {
                        cardColor = const Color(0xFFE74C3C).withValues(alpha: 0.08);
                        borderColor = const Color(0xFFE74C3C);
                        textColor = const Color(0xFFB71C1C);
                        trailingIcon = const Icon(Icons.cancel_rounded,
                            color: Color(0xFFE74C3C), size: 22);
                      }
                    } else if (isSelected) {
                      cardColor = const Color(0xFF1E65C5).withValues(alpha: 0.08);
                      borderColor = const Color(0xFF1E65C5);
                      textColor = const Color(0xFF1E65C5);
                    }

                    final letters = ['A', 'B', 'C', 'D'];

                    return GestureDetector(
                      onTap: () => _selectAnswer(id, isCorrect),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8, offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: isSelected && !_isAnswered
                                    ? const Color(0xFF1E65C5)
                                    : borderColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  letters[i.clamp(0, 3)],
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected && !_isAnswered
                                          ? Colors.white
                                          : borderColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                answer['text'] as String? ?? '',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor),
                              ),
                            ),
                            if (trailingIcon != null) trailingIcon,
                          ],
                        ),
                      ),
                    );
                  }),

                  // Explication
                  if (_isAnswered && question['explanation'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E65C5).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1E65C5).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFF1E65C5), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              question['explanation'] as String? ?? '',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Color(0xFF1E65C5),
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bouton suivant
          if (_isAnswered)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16, offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentIndex < _questions.length - 1
                        ? const Color(0xFF1E65C5)
                        : const Color(0xFFFF7F27),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 3,
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1
                        ? 'Question suivante →'
                        : 'Voir les résultats 🏆',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    String label;
    switch (difficulty) {
      case 'HARD':
        color = const Color(0xFFE74C3C);
        label = 'Difficile';
        break;
      case 'MEDIUM':
        color = const Color(0xFFF39C12);
        label = 'Moyen';
        break;
      default:
        color = const Color(0xFF27AE60);
        label = 'Facile';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}
