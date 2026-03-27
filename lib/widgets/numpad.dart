import 'package:flutter/material.dart';

class NumPad extends StatelessWidget {
  final Function(String) onKeyTap;
  final VoidCallback onClear;
  final VoidCallback onConfirm;
  final String currentValue;

  const NumPad({
    super.key,
    required this.onKeyTap,
    required this.onClear,
    required this.onConfirm,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildActionKey('清除', Colors.orange, onClear),
              _buildKey('0'),
              _buildActionKey('确认', Colors.green, onConfirm),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onKeyTap(number),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
