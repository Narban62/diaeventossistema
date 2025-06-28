class Factura {
  String cliente;
  double monto;
  String fecha;
  String archivoUrl;

  Factura({
    required this.cliente,
    required this.monto,
    required this.fecha,
    required this.archivoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'cliente': cliente,
      'monto': monto,
      'fecha': fecha,
      'archivoUrl': archivoUrl,
    };
  }

  static Factura fromMap(Map<String, dynamic> map) {
    return Factura(
      cliente: map['cliente'] ?? '',
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'] ?? '',
      archivoUrl: map['archivoUrl'] ?? '',
    );
  }
}
