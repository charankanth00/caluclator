import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const NovaCalculatorApp());
}

class NovaCalculatorApp extends StatefulWidget {
  const NovaCalculatorApp({super.key});

  @override
  State<NovaCalculatorApp> createState() => _NovaCalculatorAppState();
}

class _NovaCalculatorAppState extends State<NovaCalculatorApp> {
  bool _isDark = true;

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova Calculator',
      debugShowCheckedModeBanner: false,
      theme: _isDark
          ? ThemeData.dark(useMaterial3: true).copyWith(
              scaffoldBackgroundColor: Colors.black,
            )
          : ThemeData.light(useMaterial3: true).copyWith(
              scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            ),
      home: CalculatorHome(
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class CalculationItem {
  final String expression;
  final String result;
  const CalculationItem(this.expression, this.result);
}

class CalculatorHome extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const CalculatorHome({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _resetOnNextDigit = false;
  final List<CalculationItem> _history = [];

  void _inputDigit(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_display == '0' || _resetOnNextDigit || _display == 'Error') {
        _display = digit;
        _resetOnNextDigit = false;
      } else if (_display.length < 12) {
        _display += digit;
      }
    });
  }

  void _inputDecimal() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_resetOnNextDigit || _display == 'Error') {
        _display = '0.';
        _resetOnNextDigit = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _resetOnNextDigit = false;
    });
  }

  void _backspace() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_resetOnNextDigit || _display == 'Error') {
        _display = '0';
        _resetOnNextDigit = false;
      } else if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
        if (_display == '-' || _display.isEmpty) {
          _display = '0';
        }
      } else {
        _display = '0';
      }
    });
  }

  void _toggleSign() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_display == '0' || _display == 'Error') return;
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _percent() {
    HapticFeedback.lightImpact();
    final val = double.tryParse(_display);
    if (val == null) return;
    setState(() {
      _display = _format(val / 100.0);
    });
  }

  void _selectOperator(String op) {
    HapticFeedback.mediumImpact();
    final current = double.tryParse(_display) ?? 0.0;
    setState(() {
      if (_firstOperand != null && _operator != null && !_resetOnNextDigit) {
        final computed = _eval(_firstOperand!, current, _operator!);
        _firstOperand = computed;
        _display = _format(computed);
      } else {
        _firstOperand = current;
      }
      _operator = op;
      _expression = '${_format(_firstOperand!)} $op';
      _resetOnNextDigit = true;
    });
  }

  void _calculateResult() {
    if (_firstOperand == null || _operator == null) return;
    HapticFeedback.heavyImpact();
    final second = double.tryParse(_display) ?? 0.0;
    final fullExp = '$_expression ${_format(second)}';
    final result = _eval(_firstOperand!, second, _operator!);
    final formatted = _format(result);

    setState(() {
      _display = formatted;
      _history.insert(0, CalculationItem(fullExp, formatted));
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _resetOnNextDigit = true;
    });
  }

  double _eval(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? double.nan : a / b;
      default:
        return b;
    }
  }

  String _format(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value == value.truncateToDouble() && value.abs() < 1e12) {
      return value.toInt().toString();
    }
    String text = value.toStringAsFixed(8);
    text = text.replaceAll(RegExp(r'0+$'), '');
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  void _openHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDark ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _history.clear());
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: _history.isEmpty
                      ? const Center(child: Text('No history yet'))
                      : ListView.builder(
                          itemCount: _history.length,
                          itemBuilder: (_, idx) {
                            final item = _history[idx];
                            return ListTile(
                              title: Text(item.expression),
                              subtitle: Text(
                                '= ${item.result}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _display = item.result;
                                  _resetOnNextDigit = true;
                                });
                                Navigator.of(sheetContext).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                      widget.isDark ? Icons.light_mode : Icons.dark_mode,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: _openHistorySheet,
                    icon: Icon(Icons.history, color: textColor),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 22, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: _display.length > 8 ? 48 : 68,
                          fontWeight: FontWeight.w300,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildExpandedRow(['AC', '+/-', '%', '÷']),
                    _buildExpandedRow(['7', '8', '9', '×']),
                    _buildExpandedRow(['4', '5', '6', '-']),
                    _buildExpandedRow(['1', '2', '3', '+']),
                    _buildExpandedRow(['0', '.', '⌫', '=']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedRow(List<String> labels) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: labels.map((label) => _buildCalcButton(label)).toList(),
      ),
    );
  }

  Widget _buildCalcButton(String label) {
    final isOperator = ['÷', '×', '-', '+', '='].contains(label);
    final isTopRow = ['AC', '+/-', '%'].contains(label);

    Color bgColor;
    Color fgColor;

    if (isOperator) {
      bgColor = const Color(0xFFFF9F0A);
      fgColor = Colors.white;
    } else if (isTopRow) {
      bgColor = widget.isDark ? const Color(0xFFA5A5A5) : const Color(0xFFD4D4D2);
      fgColor = Colors.black;
    } else {
      bgColor = widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
      fgColor = widget.isDark ? Colors.white : Colors.black;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          onPressed: () => _handlePress(label, isOperator),
          child: Text(
            label,
            style: TextStyle(
              fontSize: label == '⌫' ? 22 : 28,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _handlePress(String label, bool isOperator) {
    if (RegExp(r'^[0-9]$').hasMatch(label)) {
      _inputDigit(label);
    } else if (label == '.') {
      _inputDecimal();
    } else if (isOperator && label != '=') {
      _selectOperator(label);
    } else if (label == '=') {
      _calculateResult();
    } else if (label == 'AC') {
      _clearAll();
    } else if (label == '+/-') {
      _toggleSign();
    } else if (label == '%') {
      _percent();
    } else if (label == '⌫') {
      _backspace();
    }
  }
}
