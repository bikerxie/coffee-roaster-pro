import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/roast_session.dart';

/// 烘焙曲线图表
class RoastChart extends StatelessWidget {
  final List<RoastDataPoint> dataPoints;
  final List<RoastEvent> events;

  const RoastChart({
    super.key,
    required this.dataPoints,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图例
          Row(
            children: [
              _buildLegendItem('豆温', Colors.orange),
              const SizedBox(width: 16),
              _buildLegendItem('风温', Colors.red),
              const SizedBox(width: 16),
              _buildLegendItem('RoR', Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          
          // 图表
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 50,
                  verticalInterval: 60,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800],
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800],
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 60,
                      getTitlesWidget: (value, meta) {
                        final minutes = (value / 60).floor();
                        final seconds = (value % 60).floor();
                        return Text(
                          '$minutes:${seconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                    axisNameWidget: Text(
                      '时间 (分:秒)',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}°C',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                    axisNameWidget: Text(
                      '温度',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                    axisNameWidget: Text(
                      'RoR',
                      style: TextStyle(color: Colors.green, fontSize: 10),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[800]!),
                ),
                minX: 0,
                maxX: dataPoints.isEmpty 
                  ? 600 
                  : (dataPoints.last.timestamp.difference(dataPoints.first.timestamp).inSeconds + 60).toDouble(),
                minY: 0,
                maxY: 300,
                lineBarsData: [
                  // 豆温曲线
                  _buildTempLine(dataPoints, Colors.orange, true),
                  // 风温曲线
                  _buildTempLine(dataPoints, Colors.red, false),
                  // RoR曲线
                  _buildRoorLine(dataPoints),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF3D3D3D),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}°C',
                          TextStyle(
                            color: spot.bar.color,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                // 事件标记线
                extraLinesData: ExtraLinesData(
                  verticalLines: events.map((event) {
                    final seconds = dataPoints.isEmpty 
                      ? 0 
                      : event.timestamp.difference(dataPoints.first.timestamp).inSeconds.toDouble();
                    return VerticalLine(
                      x: seconds,
                      color: _getEventColor(event.type),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        style: TextStyle(
                          color: _getEventColor(event.type),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        labelResolver: (line) => event.displayName,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildTempLine(
    List<RoastDataPoint> data, 
    Color color, 
    bool isBeanTemp
  ) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        final seconds = data.isEmpty 
          ? 0 
          : entry.value.timestamp.difference(data.first.timestamp).inSeconds.toDouble();
        return FlSpot(
          seconds,
          isBeanTemp ? entry.value.beanTemp : entry.value.airTemp,
        );
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  LineChartBarData _buildRoorLine(List<RoastDataPoint> data) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        final seconds = data.isEmpty 
          ? 0 
          : entry.value.timestamp.difference(data.first.timestamp).inSeconds.toDouble();
        return FlSpot(
          seconds,
          entry.value.roor,
        );
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.3,
      color: Colors.green,
      barWidth: 1.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'fc':
        return Colors.yellow;
      case 'sc':
        return Colors.orange;
      case 'drop':
        return Colors.red;
      case 'charge':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}