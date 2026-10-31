import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

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

    Position? posicao;

    // ETAPA 1: Captura direta do GPS (Abordagem híbrida e robusta para Web/App)
    try {
      debugPrint("Iniciando captura do GPS...");
      
      // Solicita a permissão diretamente caso o navegador precise
      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      debugPrint("GPS Obtido com sucesso: ${posicao.latitude}, ${posicao.longitude}");
    } on PermissionDeniedException catch (e) {
      if (mounted) setState(() => _statusMensagem = "ERRO: PERMISSÃO DE GPS NEGADA.");
      return;
    } on LocationServiceDisabledException catch (e) {
      if (mounted) setState(() => _statusMensagem = "ERRO: ATIVE O GPS DO SEU CELULAR.");
      return;
    } on TimeoutException catch (e) {
      if (mounted) setState(() => _statusMensagem = "ERRO: GPS DEMOROU DEMAIS. TENTE DE NOVO.");
      return;
    } catch (e) {
      if (mounted) setState(() => _statusMensagem = "ERRO NO GPS: ${e.toString()}");
      return;
    }

    // ETAPA 2: Envio em Tempo Real para o Firebase via API REST (HTTP POST)
    try {
      if (mounted) setState(() => _statusMensagem = "ENVIANDO LOCALIZAÇÃO PARA A CENTRAL...");

      final DateTime agora = DateTime.now();
      final String linkMaps = "https://www.google.com/maps?q=${posicao.latitude},${posicao.longitude}";

      final url = Uri.parse('https://samu-localizador-default-rtdb.firebaseio.com/chamados.json');
      
      final resposta = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({
          'latitude': posicao.latitude,
          'longitude': posicao.longitude,
          'precisao': posicao.accuracy,
          'horario': agora.toIso8601String(),
          'mapa': linkMaps,
          'origem': kIsWeb ? 'Web Navegador' : 'Aplicativo Nativo',
        }),
      );

      if (resposta.statusCode != 200) {
        throw Exception("Código HTTP ${resposta.statusCode}: ${resposta.body}");
      }

      if (mounted) setState(() => _statusMensagem = "LOCALIZAÇÃO ENVIADA COM SUCESSO!");
    } catch (e) {
      // Falhas de rede com o banco nunca podem impedir a chamada telefônica de emergência
      if (mounted) setState(() => _statusMensagem = "FALHA AO SALVAR NO BANCO: ${e.toString()}");
    }

    // ETAPA 3: Disparo Obrigatório do Telefone (Sempre roda independente do banco)
    if (mounted) {
      setState(() {
        _carregando = false;
        _statusMensagem = "LIGANDO PARA O 192...";
      });
    }
    
    final Uri telefoneUri = Uri(scheme: 'tel', path: '192');
    if (await canLaunchUrl(telefoneUri)) {
      await launchUrl(telefoneUri);
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

                Column(
                  children: [
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
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
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
