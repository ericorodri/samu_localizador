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
        brightness: Brightness.dark,
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 35.0, horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Topo da tela: Títulos
                const Column(
                  children: [
                    Text(
                      "S A M U   1 9 2",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "SISTEMA ÚNICO DE SAÚDE",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

                // Centro da tela: Imagem do Símbolo Fixa (Não clicável) com brilho
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.25),
                            spreadRadius: 10,
                            blurRadius: 35,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 230,
                      height: 230,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/simbolosamuapp.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.local_hospital, size: 80, color: Colors.red);
                        },
                      ),
                    ),
                  ],
                ),

                // Parte inferior: Botão de Emergência e Caixa de Status
                Column(
                  children: [
                    // Novo Botão "Chamar Ambulância"
                    ElevatedButton.icon(
                      onPressed: _carregando ? null : acionarEmergencia,
                      icon: _carregando 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.phone_in_talk, color: Colors.white),
                      label: const Text(
                        "CHAMAR AMBULÂNCIA",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        minimumSize: const Size(double.infinity, 55), // Botão largo e fácil de clicar
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Caixa de Status da mensagem
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withOpacity(0.15)),
                      ),
                      child: Text(
                        _statusMensagem,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
    );
  }
}
