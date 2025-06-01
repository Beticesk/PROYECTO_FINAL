import 'package:flutter/material.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        title: const Text(
          'Centro de Rehabilitación Integral',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text(
              'Iniciar Sesión',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 110,
                          backgroundImage: AssetImage('assets/CRI.jpg'),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Bienvenidos a la Familia CRI',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'En el CRI brindamos atención especializada a personas con discapacidad, buscando mejorar su calidad de vida mediante terapias, atención médica y programas sociales.',
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        _buildCard(
                          title: '¿Quiénes somos?',
                          content:
                              'Somos una institución dedicada al bienestar y desarrollo integral de personas con discapacidad. Trabajamos con amor, profesionalismo y compromiso.',
                        ),
                        const SizedBox(height: 40),
                        _buildCard(
                          title: 'Contáctanos',
                          content:
                              '📞 Tel: 123-456-7890\n✉️ Email: contacto@cri.mx\n📍 Dirección: Calle Salud #123, Ciudad Bienestar.',
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({required String title, required String content}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
