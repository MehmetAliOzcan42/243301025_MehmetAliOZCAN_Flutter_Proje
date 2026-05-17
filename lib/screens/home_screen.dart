import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'form_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;

  const HomeScreen({super.key, required this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Veritabanından çekilecek dinamik randevu listesi
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true; // Yükleniyor animasyonu kontrolü

  @override
  void initState() {
    super.initState();
    _fetchAppointments(); // Sayfa açılır açılmaz verileri veritabanından çeker.
  }

  // Supabase'den randevuları çeken fonksiyon
  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Randevu tablosunu Hasta, Hekim ve RandevuDetay tablolarıyla joinleyerek gerekli tüm bilgileri tek sorguda çekiyoruz.
      var query = supabase.from('Randevu').select('''
        RandevuID,
        Tarih,
        Saat,
        Durum,
        Hasta!inner (HastaID, Ad, Soyad, TCNO, Telefon, Eposta),
        Hekim (HekimID, Ad, Soyad),
        RandevuDetay (
          Tedavi (TedaviID, Ad, Ucret)
        )
      ''');

      // Eğer giriş yapan kişi hasta ise sadece kendi e-postasına ait randevuları görsün
      if (widget.userRole == 'patient') {
        final currentUserEmail = supabase.auth.currentUser?.email;
        if (currentUserEmail != null) {
          query = query.eq('Hasta.Eposta', currentUserEmail);
        }
      }

      final List<dynamic> response = await query;

      // Supabase'den çekilen verileri uygulama içinde kullanacağımız formatta dönüştürüyoruz
      final List<Map<String, dynamic>> yuklenenRandevular = response.map((row) {
        DateTime parsedDate = DateTime.parse(row['Tarih']);
        String formatliTarih = DateFormat('dd.MM.yyyy').format(parsedDate);

        // Randevuya ait tedaviyi alıyoruz.
        List detaylar = row['RandevuDetay'] as List;
        String tedaviAdi = "Genel Kontrol"; // Default tedavi
        if (detaylar.isNotEmpty && detaylar[0]['Tedavi'] != null) {
          tedaviAdi = detaylar[0]['Tedavi']['Ad'].toString();
        }

        return {
          "id": row['RandevuID'].toString(),
          "patient": "${row['Hasta']['Ad']} ${row['Hasta']['Soyad']}",
          "hekim": "Dt. ${row['Hekim']['Ad']} ${row['Hekim']['Soyad']}",
          "date": formatliTarih,
          "time": row['Saat'].toString(),
          "status": row['Durum'].toString(),
          "treatment": tedaviAdi,
          "tc": row['Hasta']['TCNO'].toString(),
          "telefon": row['Hasta']['Telefon'].toString(),
        };
      }).toList();

      setState(() {
        _appointments = yuklenenRandevular;
        _isLoading = false;
      });
    } catch (e) {
      _showMessage("Randevular yüklenirken hata oluştu: $e", isError: true);
      setState(() => _isLoading = false);
    }
  }

  // Randevu durumunu güncelleyen ve yapılan işlemi Log tablosuna kaydeden fonksiyon
  Future<void> _updateAppointmentStatus(
    String randevuId,
    String yeniDurum,
    String hastaAdi,
  ) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Durum güncelleme
      await supabase
          .from('Randevu')
          .update({'Durum': yeniDurum})
          .eq('RandevuID', int.parse(randevuId));

      // Log kaydı ekleme
      final aktifKullanici = supabase.auth.currentUser?.email ?? "Yönetici";
      await supabase.from('Log').insert({
        'IslemYapan': aktifKullanici,
        'IslemTipi': 'Durum Güncelleme',
        'Aciklama':
            '$hastaAdi isimli hastanın randevu durumu "$yeniDurum" olarak güncellendi.',
      });

      _showMessage("Randevu durumu başarıyla güncellendi.");
      _fetchAppointments(); // Listeyi yenile
    } catch (e) {
      _showMessage("Güncelleme sırasında hata oluştu: $e", isError: true);
      setState(() => _isLoading = false);
    }
  }

  // Randevu durumunu güncellemek için açılan dialog
  void _showStatusUpdateDialog(
    String randevuId,
    String mevcutDurum,
    String hastaAdi,
  ) {
    final List<String> durumlar = [
      'Beklemede',
      'Onaylandı',
      'Tamamlandı',
      'İptal Edildi',
      'Ertelendi',
    ];
    String selectedDurum = mevcutDurum;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                "Durum Güncelle",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              content: DropdownButtonFormField<String>(
                value: durumlar.contains(selectedDurum)
                    ? selectedDurum
                    : durumlar[0],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: durumlar.map((String durum) {
                  return DropdownMenuItem<String>(
                    value: durum,
                    child: Text(durum),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedDurum = val);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Vazgeç",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Diyaloğu kapat
                    Navigator.pop(context); // BottomSheet'i de kapat
                    _updateAppointmentStatus(
                      randevuId,
                      selectedDurum,
                      hastaAdi,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Kaydet",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.teal),
                  onPressed:
                      _fetchAppointments, // Listeyi manuel yenileme imkanı
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : _appointments.isEmpty
                ? Center(
                    child: Text(
                      "Kayıtlı randevu bulunamadı.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) =>
                        _buildAppointmentItem(_appointments[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () async {
                // FormScreen'den geri dönüldüğünde listenin otomatik yenilenmesi için bekliyoruz
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FormScreen()),
                );
                _fetchAppointments();
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.person_add_alt_1, color: Colors.white),
            )
          : null,
    );
  }

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
            _infoRow(Icons.badge_outlined, "TC Kimlik", app['tc'] ?? "-"),
            _infoRow(Icons.phone_outlined, "Telefon", app['telefon'] ?? "-"),
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
                  onPressed: () {
                    _showStatusUpdateDialog(
                      app['id'],
                      app['status'],
                      app['patient'],
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    "Durumu Güncelle",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
