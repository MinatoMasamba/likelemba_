// lib/presentation/features/tontine/screens/admin/widgets/replacement_drag_drop.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';


/// Widget de remplacement de membre par glisser-déposer.
/// Permet de stabiliser le cycle en remplaçant un membre défaillant.
class ReplacementDragDrop extends StatefulWidget {
  final String problematicMemberName;
  final List<String> availableCandidates;
  final void Function(String oldMember, String newMember)? onReplace;

  const ReplacementDragDrop({
    super.key,
    required this.problematicMemberName,
    required this.availableCandidates,
    this.onReplace,
  });

  @override
  State<ReplacementDragDrop> createState() => _ReplacementDragDropState();
}

class _ReplacementDragDropState extends State<ReplacementDragDrop> {
  static const String tag = 'ReplacementDragDrop';
  final Logger _logger = Logger();

  String? _selectedCandidate;
  bool _isDropped = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Glissez un remplaçant pour stabiliser le cycle",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Membre problématique (cible de remplacement)
            _buildMemberSlot(
              widget.problematicMemberName,
              isTarget: true,
            ),
            const Icon(Icons.swap_horiz, color: Colors.cyanAccent, size: 30),
            // Zone de drop
            DragTarget<String>(
              onWillAccept: (data) => !_isDropped && data != null,
              onAccept: (data) {
                HapticFeedback.heavyImpact();
                setState(() {
                  _selectedCandidate = data;
                  _isDropped = true;
                });
                _logger.i('$tag - Candidat "$data" déposé.');
              },
              builder: (context, candidateData, rejectedData) {
                return _buildMemberSlot(
                  _selectedCandidate ?? "Déposez ici",
                  isTarget: false,
                  isHighlighted: candidateData.isNotEmpty,
                  isFilled: _isDropped,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Liste des candidats disponibles (sources de drag)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableCandidates.map((candidate) {
            return Draggable<String>(
              data: candidate,
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent),
                  ),
                  child: Text(
                    candidate,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              childWhenDragging: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  candidate,
                  style: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  candidate,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }).toList(),
        ),
        if (_isDropped) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              _logger.i('$tag - Remplacement confirmé: ${widget.problematicMemberName} -> $_selectedCandidate');
              widget.onReplace?.call(widget.problematicMemberName, _selectedCandidate!);
              Navigator.pop(context);
            },
            child: const Text(
              "CONFIRMER LE REMPLACEMENT",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberSlot(
    String name, {
    bool isTarget = false,
    bool isHighlighted = false,
    bool isFilled = false,
  }) {
    Color borderColor;
    if (isTarget) {
      borderColor = Colors.redAccent.withOpacity(0.7);
    } else if (isFilled) {
      borderColor = Colors.greenAccent;
    } else {
      borderColor = Colors.white10;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.cyanAccent.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTarget
                ? Icons.person_remove
                : (isFilled ? Icons.person_add : Icons.add_circle_outline),
            color: isTarget
                ? Colors.redAccent
                : (isFilled ? Colors.greenAccent : Colors.white24),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isTarget ? Colors.redAccent : Colors.white,
                fontSize: 12,
                fontWeight: isFilled ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}