import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const AppSamu());
}

class AppSamu extends StatelessWidget {
  const AppSamu({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SAMU Localizador',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  bool _carregando = false;
  String _statusMensagem = "SALVAR VIDAS É A NOSSA MISSÃO";

  Future<void> acionarEmergencia() async {
    setState(() {
      _carregando = true;
      _statusMensagem = "BUSCANDO LOCALIZAÇÃO PELO GPS...";
    });

    try {
      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if (permissao == LocationPermission.deniedForever || permissao == LocationPermission.denied) {
          setState(() {
            _carregando = false;
            _statusMensagem = "ERRO: PERMISSÃO DE GPS NEGADA.";
          });
          return;
        }
      }

      Position posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      String mapaLink = "https://google.com{posicao.latitude},${posicao.longitude}";
      
      setState(() {
        _statusMensagem = "ENVIANDO MAPA E LIGANDO...";
      });

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'central.samu@seu-municipio.gov.br',
        queryParameters: {
          'subject': 'URGÊNCIA - Localização de Paciente',
          'body': 'Mensagem automática de emergência. Link do Google Maps: $mapaLink',
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }

      final Uri telefoneUri = Uri(scheme: 'tel', path: '192');
      if (await canLaunchUrl(telefoneUri)) {
        await launchUrl(telefoneUri);
      }

    } catch (e) {
      setState(() {
        _statusMensagem = "ERRO AO BUSCAR GPS. LIGUE O RASTREAMENTO.";
      });
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF110101), 
              Color(0xFF080000), 
              Color(0xFF000000), 
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    children: [
                      Text(
                        "S A M U   1 9 2",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "SISTEMA ÚNICO DE SAÚDE",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: _carregando ? null : acionarEmergencia,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.35),
                                spreadRadius: 15,
                                blurRadius: 40,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A0202), 
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: _carregando
                                ? const CircularProgressIndicator(color: Colors.red)
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emergency,
                                        size: 75,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "SAMU",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        "192",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 48,
                                          height: 0.9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Text(
                          _statusMensagem,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
