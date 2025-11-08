import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class YearlyCalendarPage extends StatefulWidget {
  final int initialYear;

  const YearlyCalendarPage({Key? key, required this.initialYear})
      : super(key: key);

  @override
  State<YearlyCalendarPage> createState() => _YearlyCalendarPageState();
}

class _YearlyCalendarPageState extends State<YearlyCalendarPage> {
  late int _year;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
  }

  void _previousYear() {
    setState(() {
      _year--;
    });
  }

  void _nextYear() {
    setState(() {
      _year++;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final background = _isDark ? Colors.black : Colors.white;
    final textColor = _isDark ? Colors.white : Colors.black;
    final sundayColor = Colors.red;

    return Scaffold(
      backgroundColor: background,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              // Swipe right - go to previous year
              _previousYear();
            } else if (details.primaryVelocity! < 0) {
              // Swipe left - go to next year
              _nextYear();
            }
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Header with year navigation
              Padding(
                padding: const EdgeInsets.only(
                    top: 24, left: 12, bottom: 10, right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: textColor),
                      onPressed: _previousYear,
                    ),
                    Text(
                      _year.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 42,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isDark ? Icons.light_mode : Icons.dark_mode,
                            color: textColor,
                          ),
                          onPressed: _toggleTheme,
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: textColor),
                          onPressed: _nextYear,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Calendar Grid
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: List.generate(4, (row) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(3, (col) {
                          final month = row * 3 + col + 1;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(6),
                              child: _MonthCell(
                                year: _year,
                                month: month,
                                textColor: textColor,
                                sundayColor: sundayColor,
                                isDark: _isDark,
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final int year, month;
  final Color textColor, sundayColor;
  final bool isDark;

  const _MonthCell({
    required this.year,
    required this.month,
    required this.textColor,
    required this.sundayColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // return the first day of the selected month
        Navigator.pop(context, DateTime(year, month, 1));
      },
      child: Column(
        children: [
          Text(
            DateFormat.MMM().format(DateTime(year, month)),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (d) {
              final wd = ["S", "M", "T", "W", "T", "F", "S"][d];
              return Expanded(
                child: Center(
                  child: Text(
                    wd,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: d == 0 ? sundayColor : textColor,
                    ),
                  ),
                ),
              );
            }),
          ),
          _MonthGrid(
            year: year,
            month: month,
            textColor: textColor,
            sundayColor: sundayColor,
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final int year, month;
  final Color textColor, sundayColor;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.textColor,
    required this.sundayColor,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = firstDay.weekday % 7;

    List<Widget> dayCells = [];

    // Empty cells before first day
    for (int i = 0; i < firstWeekday; i++) {
      dayCells.add(Expanded(child: Text("")));
    }

    // Fill days
    for (int d = 1; d <= daysInMonth; d++) {
      final weekday = (firstWeekday + d - 1) % 7;
      dayCells.add(
        Expanded(
          child: Center(
            child: Text(
              d.toString(),
              style: TextStyle(
                color: weekday == 0 ? sundayColor : textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    // Empty cells after last day
    while (dayCells.length % 7 != 0) {
      dayCells.add(Expanded(child: Text("")));
    }

    // Create week rows
    List<Row> rows = [];
    for (int i = 0; i < dayCells.length; i += 7) {
      rows.add(Row(children: dayCells.sublist(i, i + 7)));
    }

    return Column(children: rows);
  }
}
