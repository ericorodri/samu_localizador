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
  bool _localizacaoEnviada = false;
  bool _podeLigar = false; 
  String _statusMensagem = "SALVAR VIDAS É A NOSSA MISSÃO";

  Future<void> enviarDadosEmergencia() async {
    setState(() {
      _carregando = true;
      _localizacaoEnviada = false;
      _podeLigar = false;
      _statusMensagem = "BUSCANDO LOCALIZAÇÃO PELO GPS...";
    });

    Position? posicao;

    try {
      final permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        final novaPermissao = await Geolocator.requestPermission();
        if (novaPermissao == LocationPermission.denied ||
            novaPermissao == LocationPermission.deniedForever) {
          throw Exception("Permissão de GPS negada.");
        }
      }

      posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (!mounted) return;
      setState(() {
        _statusMensagem = "GPS OBTIDO! ENVIANDO PARA A CENTRAL...";
      });

      final agora = DateTime.now();
      final idChamado = agora.microsecondsSinceEpoch.toString();
      final linkMaps = "https://www.google.com/maps?q=${posicao.latitude},${posicao.longitude}";

      final dados = {
        "latitude": posicao.latitude,
        "longitude": posicao.longitude,
        "precisao": posicao.accuracy,
        "horario": agora.toIso8601String(),
        "mapa": linkMaps,
        "origem": kIsWeb ? "Web Navegador" : "Aplicativo Nativo",
        "status": "NOVO",
      };

      final url = Uri.parse(
        "https://samu-localizador-default-rtdb.firebaseio.com/chamados/$idChamado.json"
      );

      final resposta = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(dados),
      ).timeout(const Duration(seconds: 15));

      debugPrint("FIREBASE STATUS: ${resposta.statusCode}");

      if (resposta.statusCode != 200) {
        throw Exception("HTTP ${resposta.statusCode}: ${resposta.body}");
      }

      if (!mounted) return;
      setState(() {
        _localizacaoEnviada = true;
        _podeLigar = true;
        _statusMensagem = "LOCALIZAÇÃO ENVIADA COM SUCESSO! LIGUE PARA 192.";
      });

    } catch (e, stackTrace) {
      debugPrint("ERRO NO ENVIO: $e");
      debugPrint("DETALHES: $stackTrace");

      if (mounted) {
        setState(() {
          _localizacaoEnviada = false;
          _podeLigar = true; // Segurança operacional garantida: libera o botão mesmo sem rede
          _statusMensagem = "FALHA NO ENVIO: $e\nLIGUE DIRETO PARA O 192!";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> dispararLigacao() async {
    final Uri telefoneUri = Uri(scheme: 'tel', path: '192');

    try {
      // Ajuste do Claude: Removido o modo externo para garantir compatibilidade nativa pura
      final ok = await launchUrl(telefoneUri);
      
      if (!ok && mounted) {
        setState(() {
          _statusMensagem = "NÃO FOI POSSÍVEL ABRIR O DISCADOR. DIGITE 192.";
        });
      }
    } catch (e) {
      debugPrint("ERRO AO ABRIR DISCADOR: $e");
      if (mounted) {
        setState(() {
          _statusMensagem = "ERRO AO DISCAR. ABRA O TELEFONE E DIGITE 192.";
        });
      }
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
                            color: _podeLigar
                                ? (_localizacaoEnviada ? Colors.green.withOpacity(0.25) : Colors.orange.withOpacity(0.25))
                                : Colors.red.withOpacity(0.25),
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
                      onPressed: _carregando
                          ? null
                          : (_podeLigar ? dispararLigacao : enviarDadosEmergencia),
                      icon: _carregando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Icon(
                              _podeLigar ? Icons.phone_in_talk : Icons.location_on,
                              color: Colors.white,
                            ),
                      label: Text(
                        _podeLigar ? "LIGAR PARA O 192 AGORA" : "ENVIAR LOCALIZAÇÃO",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _podeLigar
                            ? (_localizacaoEnviada ? Colors.green.shade700 : Colors.amber.shade900)
                            : Colors.red.shade700,
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
                        border: Border.all(
                          color: _podeLigar 
                              ? (_localizacaoEnviada ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15)) 
                              : Colors.red.withOpacity(0.15)
                        ),
                      ),
                      child: Text(
                        _statusMensagem,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
