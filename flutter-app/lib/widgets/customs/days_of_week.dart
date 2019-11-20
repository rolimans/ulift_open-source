import 'package:flutter/material.dart';

class DaysOfWeek extends StatefulWidget {
  final List<bool> days;

  DaysOfWeek(this.days);

  @override
  _DaysOfWeekState createState() => _DaysOfWeekState();
}

class _DaysOfWeekState extends State<DaysOfWeek> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _buildDayField("D", 0),
        _buildDayField("S", 1),
        _buildDayField("T", 2),
        _buildDayField("Q", 3),
        _buildDayField("Q", 4),
        _buildDayField("S", 5),
        _buildDayField("S", 6),
      ],
    );
  }

  Widget _buildDayField(String text, int position) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.days[position] = !widget.days[position];
        });
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.days[position]
                ? Theme.of(context).accentColor
                : Colors.black54,
          ),
          color: widget.days[position]
              ? Theme.of(context).accentColor
              : Colors.white,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: widget.days[position] ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}
