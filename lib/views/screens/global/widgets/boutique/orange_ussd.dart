// pubspec.yaml
// Ajoutez ces dépendances :
// url_launcher: ^6.2.1
// permission_handler: ^11.0.1

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class OrangeMoneyPayment {
  // Codes marchands - À remplacer par vos vrais codes
  static const String CODE_MARCHAND_ELEGANTFASO = "123456"; // Votre code marchand

  // Générer le code USSD pour paiement marchand
  static String generatePaymentUSSD({
    required double montant,
    required String codeMarchand,
  }) {
    // Format: #144*1*3*MONTANT*CODE_MARCHAND#
    return "#144*1*3*${montant.toInt()}*$codeMarchand#";
  }

  // Lancer l'USSD
  static Future<bool> launchPaymentUSSD({
    required double montant,
    String? codeMarchand,
  }) async {
    try {
      // Vérifier les permissions
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
        if (!status.isGranted) {
          throw Exception("Permission téléphone requise");
        }
      }

      final ussdCode = generatePaymentUSSD(
        montant: montant,
        codeMarchand: codeMarchand ?? CODE_MARCHAND_ELEGANTFASO,
      );

      final uri = Uri.parse("tel:$ussdCode");

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        throw Exception("Impossible de lancer l'USSD");
      }
    } catch (e) {
      print("Erreur USSD: $e");
      return false;
    }
  }
}

// Widget de paiement Orange Money
class OrangeMoneyPaymentWidget extends StatefulWidget {
  final double montant;
  final String? reference;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const OrangeMoneyPaymentWidget({
    Key? key,
    required this.montant,
    this.reference,
    this.onSuccess,
    this.onCancel,
  }) : super(key: key);

  @override
  State<OrangeMoneyPaymentWidget> createState() => _OrangeMoneyPaymentWidgetState();
}

class _OrangeMoneyPaymentWidgetState extends State<OrangeMoneyPaymentWidget> {
  bool _isProcessing = false;

  Future<void> _initiatePayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Afficher les instructions avant de lancer l'USSD
      await _showInstructions();

      // Lancer l'USSD
      final success = await OrangeMoneyPayment.launchPaymentUSSD(
        montant: widget.montant,
      );

      if (success) {
        // Attendre que l'utilisateur termine la transaction
        await _showConfirmationDialog();
      } else {
        _showErrorDialog("Impossible de lancer le paiement Orange Money");
      }
    } catch (e) {
      _showErrorDialog("Erreur: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showInstructions() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: Colors.orange),
            SizedBox(width: 8),
            Text("Orange Money"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Montant: ${widget.montant.toInt()} FCFA"),
            const SizedBox(height: 16),
            const Text(
              "Instructions:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("1. Votre app de téléphone va s'ouvrir"),
            const Text("2. Le code USSD sera pré-rempli"),
            const Text("3. Appuyez sur 'Appeler'"),
            const Text("4. Suivez les instructions Orange Money"),
            const Text("5. Saisissez votre code PIN"),
            const Text("6. Confirmez le paiement"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCancel?.call();
            },
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text("Continuer"),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Paiement en cours"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text("Avez-vous terminé le paiement Orange Money ?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCancel?.call();
            },
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSuccess?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text("Paiement effectué"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Erreur"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCancel?.call();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_android, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                "Orange Money",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Montant: ${widget.montant.toInt()} FCFA"),
          if (widget.reference != null) ...[
            const SizedBox(height: 4),
            Text("Référence: ${widget.reference}"),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isProcessing
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text("Payer avec Orange Money"),
            ),
          ),
        ],
      ),
    );
  }
}

// Exemple d'utilisation dans votre page de commande
class CommandePaymentPage extends StatelessWidget {
  final double montantTotal;
  final String referenceCommande;

  const CommandePaymentPage({
    Key? key,
    required this.montantTotal,
    required this.referenceCommande,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiement"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choisissez votre mode de paiement :",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Orange Money
            OrangeMoneyPaymentWidget(
              montant: montantTotal,
              reference: referenceCommande,
              onSuccess: () {
                // Traiter le succès du paiement
                _handlePaymentSuccess();
              },
              onCancel: () {
                // Gérer l'annulation
                Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 16),

            // Moov Money (similaire)
            _buildMoovMoneyOption(),

            const SizedBox(height: 16),

            // Wave (si disponible)
            _buildWaveOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildMoovMoneyOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_android, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                "Moov Money",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Montant: ${montantTotal.toInt()} FCFA"),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Code USSD Moov Money: #777*montant*numero_marchand#
                _launchMoovMoney();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Payer avec Moov Money"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.purple, size: 24),
              SizedBox(width: 8),
              Text(
                "Wave",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Montant: ${montantTotal.toInt()} FCFA"),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Redirection vers Wave ou QR code
                _launchWave();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Payer avec Wave"),
            ),
          ),
        ],
      ),
    );
  }

  void _launchMoovMoney() async {
    // Code USSD Moov Money (à adapter selon votre code marchand)
    const codeMarchand = "VOTRE_CODE_MOOV";
    final ussdCode = "#777*${montantTotal.toInt()}*$codeMarchand#";

    final uri = Uri.parse("tel:$ussdCode");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWave() {
    // Pour Wave, vous pourriez utiliser un QR code ou deep link
    // selon leur API
  }

  void _handlePaymentSuccess() {
    // Traiter le succès du paiement
    // Mettre à jour le statut de la commande
    // Rediriger vers la page de confirmation
    print("Paiement réussi pour la commande: $referenceCommande");
  }
}