// import 'package:flutter/material.dart';
// import 'package:svg_path_parser/svg_path_parser.dart';

// class SVGPainter extends CustomPainter {
//   final Path path;
//   final Color color;
//   final bool showPath;
//   final Color pathColor;

//   SVGPainter(
//     this.path,
//     this.color,
//     this.showPath,
//     this.pathColor,
//   );

//   @override
//   void paint(Canvas canvas, Size size) {
//     var paint = Paint()
//       ..color = this.color ?? Colors.white
//       ..strokeWidth = 4.0;
//     canvas.drawPath(path, paint);
//     if (showPath) {
//       var border = Paint()
//         ..color = this.pathColor ?? Colors.black
//         ..strokeWidth = 1.0
//         ..style = PaintingStyle.stroke;
//       canvas.drawPath(path, border);
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }

// class SVGPath {
//   final String path;
//   final Color color;

//   SVGPath(this.path, this.color);
// }

// class SVGPathWidget extends StatelessWidget {
//   final List<SVGPath> paths;
//   final double size;
//   final bool showPath;
//   final Color pathColor;

//   SVGPathWidget({
//     this.paths,
//     this.size = 50.0,
//     this.showPath = false,
//     this.pathColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: this.size,
//       width: this.size,
//       child: Stack(
//         children: this
//             .paths
//             .map(
//               (path) => CustomPaint(
//                 painter: SVGPainter(
//                   parseSvgPath(path.path),
//                   path.color,
//                   this.showPath,
//                   this.pathColor,
//                 ),
//               ),
//             )
//             .toList(),
//       ),
//     );
//   }
// }
