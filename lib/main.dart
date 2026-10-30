import 'dart:convert';
import 'package:flutter/material.dart';
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

    try {
      // 1. Verifica e solicita permissão de GPS
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

      // 2. Captura a localização atual com alta precisão
      Position posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _statusMensagem = "ENVIANDO LOCALIZAÇÃO PARA A CENTRAL...";
      });

      // 3. Envio invisível e anônimo para o Firebase Realtime Database
      final DateTime agora = DateTime.now();
      final String idChamado = agora.millisecondsSinceEpoch.toString();
      final String linkGoogleMaps = "https://google.com{posicao.latitude},${posicao.longitude}";

      // URL corrigida de acordo com o painel real do seu projeto
      final url = Uri.parse('https://firebaseio.com');
      
      await http.put(
        url,
        body: json.encode({
          'latitude': posicao.latitude,
          'longitude': posicao.longitude,
          'horario': agora.toIso8601String(),
          'mapa': linkGoogleMaps,
        }),
      );

      setState(() {
        _statusMensagem = "LOCALIZAÇÃO ENVIADA! LIGANDO PARA O 192...";
      });

      // 4. Abre imediatamente o discador nativo chamando o 192
      final Uri telephoneUri = Uri(scheme: 'tel', path: '192');
      if (await canLaunchUrl(telephoneUri)) {
        await launchUrl(telephoneUri);
      }

    } catch (e) {
      setState(() {
        _statusMensagem = "ERRO AO ACIONAR O GPS OU BANCO.";
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
                const Column(
                  children: [
                    Text(
                      "S A M U   1 2",
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
