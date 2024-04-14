import 'package:chanceshfit/card_list.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CardDisplay extends StatefulWidget {
  final CardInfo cardInfo;
  bool selected;
  bool used;
  final void Function(bool) onSelected; // Add the onSelected callback

  CardDisplay(
      {super.key,
      required this.cardInfo,
      required this.selected,
      required this.used,
      required this.onSelected});

  @override
  State<CardDisplay> createState() => _CardDisplayState();
}

class _CardDisplayState extends State<CardDisplay>
    with SingleTickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 300);

  void toggleExpanded() {
    setState(() {
      widget.selected = !widget.selected;
    });
  }

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () => widget.onSelected(!widget.selected),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AnimatedContainer(
            duration: duration,
            width: 150,
            height: (widget.selected && !widget.used) ? 125 : 20,
            curve: Curves.ease,
            child: widget.used
                ? CardSmallDisplayScreen(
                    cardInfo: widget.cardInfo, used: widget.used)
                : AnimatedCrossFade(
                    duration: duration,
                    firstCurve: Curves.easeInOutCubic,
                    secondCurve: Curves.easeInOutCubic,
                    crossFadeState: widget.selected
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    // Use Positioned.fill() to pass the constraints to its children.
                    // This allows the Images to use BoxFit.cover to cover the correct
                    // size
                    layoutBuilder:
                        (topChild, topChildKey, bottomChild, bottomChildKey) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            key: bottomChildKey,
                            child: bottomChild,
                          ),
                          Positioned.fill(
                            key: topChildKey,
                            child: topChild,
                          ),
                        ],
                      );
                    },
                    firstChild: CardSmallDisplayScreen(
                        cardInfo: widget.cardInfo, used: widget.used),
                    secondChild: CardDisplayScreen(cardInfo: widget.cardInfo),
                  ),
          ),
        ),
      ),
    );
  }
}

class CardSmallDisplayScreen extends StatelessWidget {
  const CardSmallDisplayScreen(
      {super.key, required this.cardInfo, required this.used});

  final CardInfo cardInfo;
  final bool used;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          width: 150,
          decoration: BoxDecoration(
            color: used ? Colors.grey : Colors.blue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            cardInfo.name,
            style: const TextStyle(fontSize: 15),
            textAlign: TextAlign.center,
          )),
    );
  }
}

class CardDisplayScreen extends StatefulWidget {
  const CardDisplayScreen({Key? key, required this.cardInfo});

  final CardInfo cardInfo;

  @override
  _CardDisplayScreenState createState() => _CardDisplayScreenState();
}

class _CardDisplayScreenState extends State<CardDisplayScreen> {
  TextStyle _selectTextStyle(int value) {
    switch (value.sign) {
      case 0:
        return const TextStyle(
            fontWeight: FontWeight.normal, color: Colors.black);
      case 1:
        return const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.green);
      case -1:
        return const TextStyle(fontWeight: FontWeight.bold, color: Colors.red);
      default:
        return const TextStyle(
            fontWeight: FontWeight.normal, color: Colors.black);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(widget.cardInfo.name, textAlign: TextAlign.center),
              Text('Chance: ${widget.cardInfo.chanceValue}',
                  style: _selectTextStyle(widget.cardInfo.chanceValue)),
              Text('Attack: ${widget.cardInfo.attackValue}',
                  style: _selectTextStyle(widget.cardInfo.attackValue)),
              Text(
                widget.cardInfo.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }
}
