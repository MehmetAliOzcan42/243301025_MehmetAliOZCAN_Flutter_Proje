import 'package:flutter/material.dart';
import 'form_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;

  const HomeScreen({super.key, required this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Örnek Randevular; dynamic olarak appointments tablosundan veriler çekilecek
  final List<Map<String, dynamic>> _appointments = [
    {
      "id": "1",
      "patient": "Can Berk",
      "hekim": "Dt. Arda Guler",
      "date": "18.05.2024",
      "time": "11:00",
      "status": "Onaylandı",
      "treatment": "İmplant Muayenesi",
    },
    {
      "id": "2",
      "patient": "Zeynep Sönmez",
      "hekim": "Dt. Merve Aydın",
      "date": "20.05.2024",
      "time": "15:45",
      "status": "Beklemede",
      "treatment": "Diş Taşı Temizliği",
    },
    {
      "id": "3",
      "patient": "Ahmet Yılmaz",
      "hekim": "Dt. Arda Guler",
      "date": "21.05.2024",
      "time": "10:30",
      "status": "Tamamlandı",
      "treatment": "Kanal Tedavisi",
    },
    {
      "id": "4",
      "patient": "Ayşe Demir",
      "hekim": "Dt. Merve Aydın",
      "date": "22.05.2024",
      "time": "09:00",
      "status": "İptal Edildi",
      "treatment": "Dolgu",
    },
    {
      "id": "5",
      "patient": "Mehmet Öz",
      "hekim": "Dt. Arda Guler",
      "date": "23.05.2024",
      "time": "14:00",
      "status": "Ertelendi",
      "treatment": "Diş Beyazlatma",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final String title = widget.userRole == 'admin'
        ? "Yönetici Ana Sayfa"
        : "Ana Sayfa";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            // Sağ üst köşedeki çıkış butonu kullanıcıyı çıkış yaparak giriş ekranına yönlendirir.
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.userRole == 'admin'
                      ? "Tüm Randevular"
                      : "Randevularım",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _appointments.length,
              itemBuilder: (context, index) =>
                  _buildAppointmentItem(_appointments[index]),
              // Randevu öğelerini listeleyen ListView; her randevu için _buildAppointmentItem fonksiyonunu çağırır.
            ),
          ),
        ],
      ),
      floatingActionButton: widget.userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FormScreen()),
                );
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.person_add_alt_1, color: Colors.white),
            )
          : null,
      // Sadece yönetici için geçerli buton; hastanın kaydını sisteme eklemek için kullanılır.
    );
  }

  // Randevunun durumuna göre renk atanır ve randevu bilgilerini gösteren kart yapısı oluşturulur.
  Widget _buildAppointmentItem(Map<String, dynamic> app) {
    Color statusColor;
    switch (app['status']) {
      case 'Onaylandı':
        statusColor = Colors.green;
        break;
      case 'Beklemede':
        statusColor = Colors.orange;
        break;
      case 'Tamamlandı':
        statusColor = Colors.blue;
        break;
      case 'İptal Edildi':
        statusColor = Colors.red;
        break;
      case 'Ertelendi':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.grey;
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_month, color: Colors.teal),
        ),
        title: Text(
          widget.userRole == 'admin' ? app['patient'] : app['treatment'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hekim: ${app['hekim']}"),
            Text(
              "${app['date']} - ${app['time']}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        // Randevu durumunu gösteren renkli etiket yapısı
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            app['status'],
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _showDetails(app),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Randevu Detayı",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 15),
            _infoRow(Icons.person, "Hasta", app['patient']),
            _infoRow(Icons.medical_information, "Hekim", app['hekim']),
            _infoRow(Icons.settings, "Tedavi", app['treatment']),
            _infoRow(
              Icons.access_time,
              "Zaman",
              "${app['date']} saat ${app['time']}",
            ),
            _infoRow(Icons.info_outline, "Mevcut Durum", app['status']),
            const SizedBox(height: 30),
            if (widget.userRole == 'admin')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    "Durumu Güncelle",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Randevunun detaylarını gösteren bilgiler için ortak bir widget yapısı oluşturulur.
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 15),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
