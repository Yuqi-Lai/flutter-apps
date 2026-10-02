import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const ButtonCalculator(),
      theme: ThemeData(useMaterial3: true),
    );
  }
}

// Part-1: Button-based Calculator
class ButtonCalculator extends StatefulWidget {
  const ButtonCalculator({super.key});

  @override
  State<ButtonCalculator> createState() => _ButtonCalculatorState();
}

class _ButtonCalculatorState extends State<ButtonCalculator> {
  String output = '0';
  String num1 = '';
  String operand = '';
  bool shouldResetOutput = false;

  void press(String value) {
    setState(() {
      if (value == 'C') {
        output = '0';
        num1 = '';
        operand = '';
        shouldResetOutput = false;
      } else if (value == '+' || value == '-' || value == '×' || value == '÷') {
        num1 = output;
        operand = value;
        shouldResetOutput = true;
      } else if (value == '=') {
        if (num1.isEmpty || operand.isEmpty) return;
        double n1 = double.parse(num1);
        double n2 = double.parse(output);
        double result = 0;
        if (operand == '+') result = n1 + n2;
        if (operand == '-') result = n1 - n2;
        if (operand == '×') result = n1 * n2;
        if (operand == '÷') {
          if (n2 == 0) {
            output = 'Error';
            num1 = '';
            operand = '';
            shouldResetOutput = false;
            return;
          } else {
            result = n1 / n2;
          }
        }
        output = result.toString();
        num1 = '';
        operand = '';
        shouldResetOutput = false;
      } else {
        if (shouldResetOutput) {
          output = value;
          shouldResetOutput = false;
        } else {
          if (output == '0') {
            output = value;
          } else {
            output += value;
          }
        }
      }
    });
  }

  Widget buildButton(String text) {
    return ElevatedButton(
      onPressed: () => press(text),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['7', '8', '9', '×'],
      ['4', '5', '6', '÷'],
      ['1', '2', '3', '+'],
      ['C', '0', '=', '-'],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Button Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FormCalculator()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.all(16),
                  child: Text(output, style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (var row in keys)
                        for (var label in row) buildButton(label),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Part-2: TextFormField-based Calculator
class FormCalculator extends StatefulWidget {
  const FormCalculator({super.key});

  @override
  State<FormCalculator> createState() => _FormCalculatorState();
}

class _FormCalculatorState extends State<FormCalculator> {
  final _formKey = GlobalKey<FormState>();
  final _num1Controller = TextEditingController();
  final _num2Controller = TextEditingController();
  String result = '';

  @override
  void dispose() {
    _num1Controller.dispose();
    _num2Controller.dispose();
    super.dispose();
  }

  String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a number';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  void calculate(String operation) {
    if (_formKey.currentState!.validate()) {
      double num1 = double.parse(_num1Controller.text);
      double num2 = double.parse(_num2Controller.text);
      double res = 0;

      switch (operation) {
        case '+':
          res = num1 + num2;
          break;
        case '-':
          res = num1 - num2;
          break;
        case '×':
          res = num1 * num2;
          break;
        case '÷':
          if (num2 == 0) {
            setState(() {
              result = 'Error: Division by zero';
            });
            return;
          }
          res = num1 / num2;
          break;
      }

      setState(() {
        result = 'Result: $res';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _num1Controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'First Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.looks_one),
                ),
                validator: validateNumber,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _num2Controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Second Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.looks_two),
                ),
                validator: validateNumber,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => calculate('+'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text('+', style: TextStyle(fontSize: 24)),
                  ),
                  ElevatedButton(
                    onPressed: () => calculate('-'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text('-', style: TextStyle(fontSize: 24)),
                  ),
                  ElevatedButton(
                    onPressed: () => calculate('×'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text('×', style: TextStyle(fontSize: 24)),
                  ),
                  ElevatedButton(
                    onPressed: () => calculate('÷'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text('÷', style: TextStyle(fontSize: 24)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _num1Controller.clear();
                    _num2Controller.clear();
                    result = '';
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 24),
              if (result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
