import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:html' as html;

class FacturacionPage extends StatefulWidget {
  const FacturacionPage({super.key});

  @override
  State<FacturacionPage> createState() => _FacturacionPageState();
}

class _FacturacionPageState extends State<FacturacionPage> {
  final _clienteController = TextEditingController();
  final _montoController = TextEditingController();

  Future<void> _registrarFactura() async {
    final cliente = _clienteController.text;
    final monto = double.tryParse(_montoController.text) ?? 0;

    if (cliente.isEmpty || monto <= 0) {
      print('⚠️ Cliente o monto inválido.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente y monto válidos son requeridos.')),
      );
      return;
    }

    try {
      final docRef = await FirebaseFirestore.instance.collection('facturas').add({
        'cliente': cliente,
        'monto': monto,
        'fecha': DateTime.now().toIso8601String(),
      });

      print('✅ Factura registrada con ID: ${docRef.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura registrada exitosamente')),
      );

      _clienteController.clear();
      _montoController.clear();
    } catch (e) {
      print('❌ Error al registrar factura: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar factura: $e')),
      );
    }
  }

  Future<void> _exportarFacturasComoPDF() async {
    try {
      final pdf = pw.Document();
      final snapshot = await FirebaseFirestore.instance.collection('facturas').get();

      print('📄 Exportando ${snapshot.docs.length} facturas a PDF...');

      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Listado de Facturas', style: pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 10),
                ...snapshot.docs.map((doc) {
                  final data = doc.data();
                  return pw.Text(
                    'Cliente: ${data['cliente']} | Monto: \$${data['monto']} | Fecha: ${data['fecha']}',
                  );
                }).toList(),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
      print('✅ PDF generado correctamente.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generado con éxito')),
      );
    } catch (e) {
      print('❌ Error al exportar PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar PDF: $e')),
      );
    }
  }

  Future<void> _exportarFacturasComoExcel() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('facturas').get();
      print('📊 Exportando ${snapshot.docs.length} facturas a Excel...');

      final excel = Excel.createExcel();
      final sheet = excel['Facturas'];

      sheet.appendRow([
        TextCellValue('Cliente'),
        TextCellValue('Monto'),
        TextCellValue('Fecha'),
      ]);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        sheet.appendRow([
          TextCellValue(data['cliente'] ?? ''),
          TextCellValue(data['monto'].toString()),
          TextCellValue(data['fecha'] ?? ''),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes == null) {
        print('❌ No se pudo guardar el archivo Excel.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el archivo Excel')),
        );
        return;
      }

      final blob = html.Blob([fileBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "facturas.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);

      print('✅ Excel descargado correctamente.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel descargado correctamente')),
      );
    } catch (e) {
      print('❌ Error al exportar Excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar Excel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sistema de Facturación")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(labelText: 'Cliente'),
            ),
            TextField(
              controller: _montoController,
              decoration: const InputDecoration(labelText: 'Monto'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: _registrarFactura,
              child: const Text('Registrar Factura'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _exportarFacturasComoPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exportar PDF'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _exportarFacturasComoExcel,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Exportar Excel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('facturas').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['cliente']),
                        subtitle: Text('${data['monto']} - ${data['fecha']}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
