import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPageLoading = true;
  // Sayfa açılırken veriler veritabanından çekilirken göstermek için

  // Hasta Bilgileri Kontrolcüleri
  final TextEditingController _tcController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Supabase'den çekilecek dinamik listeler
  List<Map<String, dynamic>> _hekimlerList = [];
  List<Map<String, dynamic>> _tedavilerList = [];

  String? _selectedHekimId;
  String? _selectedTedaviId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Sayfa açılır açılmaz verileri yükle
  }

  @override
  void dispose() {
    _tcController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Supabase'den hekimler ve tedaviler verilerini çekme işlemi
  Future<void> _loadInitialData() async {
    try {
      final supabase = Supabase.instance.client;

      // Hekimlerin listesi
      final hekimlerResponse = await supabase
          .from('Hekim')
          .select('HekimID, Ad, Soyad');

      // Tedavilerin listesi
      final tedavilerResponse = await supabase
          .from('Tedavi')
          .select('TedaviID, Ad, Ucret');

      setState(() {
        _hekimlerList = List<Map<String, dynamic>>.from(hekimlerResponse);
        _tedavilerList = List<Map<String, dynamic>>.from(tedavilerResponse);
        _isPageLoading = false; // Yükleme bitti demek için
      });
    } catch (e) {
      _showMessage("Veriler çekilirken hata oluştu: $e", isError: true);
      setState(() => _isPageLoading = false);
    }
  }

  // Tarih Seçici Penceresi
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Saat Seçici Penceresi
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  // Formu kaydetme işlemi; hasta,randevu ve randevu detay tablolarına kayıt atar
  Future<void> _saveForm() async {
    // Form elemanlarının doğruluğunu kontrol etmek için
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHekimId == null ||
        _selectedTedaviId == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      _showMessage(
        "Lütfen hekim, tedavi, tarih ve saat seçiniz.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final String tcNo = _tcController.text.trim();
      int hastaId;

      // Hasta tablosunda TCNO'ya göre arama yaparak mevcut hasta var mı kontrol ediyoruz
      final mevcutHasta = await supabase
          .from('Hasta')
          .select('HastaID')
          .eq('TCNO', tcNo)
          .maybeSingle();

      if (mevcutHasta != null) {
        // Hasta zaten sistemde varsa mevcut ID'yi alıyoruz
        hastaId = mevcutHasta['HastaID'] as int;
      } else {
        final String epostaAdresi = _emailController.text.trim();
        // Supabase Auth sistemine kullanıcıyı kaydediyoruz
        // Standart şifre 123456
        await supabase.auth.signUp(email: epostaAdresi, password: '123456');
        // Hasta yoksa yeni bir hasta kaydı oluşturuyoruz
        final yeniHasta = await supabase
            .from('Hasta')
            .insert({
              'TCNO': tcNo,
              'Ad': _nameController.text.trim(),
              'Soyad': _surnameController.text.trim(),
              'Telefon': _phoneController.text.trim(),
              'Eposta': _emailController.text.trim(),
            })
            .select('HastaID')
            .single();

        hastaId = yeniHasta['HastaID'] as int;
      }

      // Tarih formatını "yyyy-MM-dd" şekline getiriyoruz
      final String formatliTarih = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate!);
      // Saat formatını "HH:mm" şekline getiriyoruz
      final String formatliSaat =
          "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

      // Randevu tablosuna yeni randevu kaydı oluşturuyoruz
      final yeniRandevu = await supabase
          .from('Randevu')
          .insert({
            'HastaID': hastaId,
            'HekimID': int.parse(_selectedHekimId!),
            'Tarih': formatliTarih,
            'Saat': formatliSaat,
            'Durum': 'Beklemede', // Varsayılan durum
          })
          .select('RandevuID')
          .single();

      final int randevuId = yeniRandevu['RandevuID'] as int;

      // RandevuDetay tablosuna tedavi detayını kaydediyoruz
      await supabase.from('RandevuDetay').insert({
        'RandevuID': randevuId,
        'TedaviID': int.parse(_selectedTedaviId!),
      });

      // Yaptığımız işlemleri Log tablosuna kaydediyoruz
      final aktifKullanici = supabase.auth.currentUser?.email ?? "Yönetici";
      await supabase.from('Log').insert({
        'IslemYapan': aktifKullanici,
        'IslemTipi': 'Randevu Kayıt',
        'Aciklama': '$tcNo TC numaralı hastaya yeni randevu oluşturuldu.',
      });

      _showMessage("Randevu başarıyla oluşturuldu ve loglandı.");

      if (!mounted) return;
      Navigator.pop(context); // İşlem başarıyla bittiğinde ana sayfaya dön
    } catch (e) {
      _showMessage("Kaydedilirken bir hata oluştu: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Randevu Kayıt",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hasta Bilgileri
                          const Row(
                            children: [
                              Icon(Icons.person, color: Colors.teal),
                              SizedBox(width: 8),
                              Text(
                                "Hasta Bilgileri",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          _buildInput(
                            "TC Kimlik No",
                            _tcController,
                            Icons.badge_outlined,
                            isNum: true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInput(
                                  "Ad",
                                  _nameController,
                                  Icons.person_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInput(
                                  "Soyad",
                                  _surnameController,
                                  Icons.person_outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInput(
                            "Telefon",
                            _phoneController,
                            Icons.phone_outlined,
                            isNum: true,
                          ),
                          const SizedBox(height: 12),
                          _buildInput(
                            "E-posta",
                            _emailController,
                            Icons.email_outlined,
                          ),

                          const SizedBox(height: 30),
                          const Divider(),
                          const SizedBox(height: 15),

                          // Randevu Bilgileri
                          const Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.teal),
                              SizedBox(width: 8),
                              Text(
                                "Randevu Bilgileri",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // Hekim Dropdown Menüsü (Veritabanından dinamik olarak çekilen verilerle)
                          _buildDropdown(
                            "Hekim Seçiniz",
                            Icons.medical_information_outlined,
                            _hekimlerList.map((hekim) {
                              return {
                                'id': hekim['HekimID'].toString(),
                                'display':
                                    "Dt. ${hekim['Ad']} ${hekim['Soyad']}",
                              };
                            }).toList(),
                            _selectedHekimId,
                            (val) => setState(() => _selectedHekimId = val),
                          ),
                          const SizedBox(height: 12),

                          // Tedavi Dropdown Menüsü (Veritabanından dinamik olarak çekilen verilerle)
                          _buildDropdown(
                            "Tedavi Türü",
                            Icons.medical_services_outlined,
                            _tedavilerList.map((tedavi) {
                              final ucret = tedavi['Ucret'];
                              return {
                                'id': tedavi['TedaviID'].toString(),
                                'display':
                                    "${tedavi['Ad']} (${ucret.toString()} TL)",
                              };
                            }).toList(),
                            _selectedTedaviId,
                            (val) => setState(() => _selectedTedaviId = val),
                          ),
                          const SizedBox(height: 12),

                          // Tarih ve Saat Seçimi
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(15),
                                  child: _buildPickerBox(
                                    Icons.event,
                                    _selectedDate == null
                                        ? "Tarih Seç"
                                        : DateFormat(
                                            'dd.MM.yyyy',
                                          ).format(_selectedDate!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickTime,
                                  borderRadius: BorderRadius.circular(15),
                                  child: _buildPickerBox(
                                    Icons.access_time,
                                    _selectedTime == null
                                        ? "Saat Seç"
                                        : _selectedTime!.format(context),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Yapılan işlemi kaydetmek için buton
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveForm,
                              icon: _isLoading
                                  ? const SizedBox()
                                  : const Icon(Icons.save, color: Colors.white),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              label: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "RANDEVUYU KAYDET",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Verilerin girildiği ortak TextFormField yapısı
  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNum = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.teal, size: 22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.teal, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "$label gerekli" : null,
    );
  }

  // Verilerin dinamik olarak çekildiği ortak DropdownButtonFormField yapısı
  Widget _buildDropdown(
    String label,
    IconData icon,
    List<Map<String, dynamic>> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.teal),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.teal, size: 22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.teal, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['id'],
          child: Text(item['display'] ?? ""),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "$label seçilmelidir" : null,
    );
  }

  // Tarih ve Saat Seçimi için Ortak Kutu Tasarımı
  Widget _buildPickerBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 22),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: text.contains("Seç") ? Colors.grey[600] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
