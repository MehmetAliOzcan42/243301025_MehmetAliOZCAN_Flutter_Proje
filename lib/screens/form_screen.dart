import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//Tarih formatlama için intl paketi kullanıldı.

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  // Form doğrulaması için global key
  bool _isLoading = false;
  // Form kaydedilirken yükleniyor durumunu göstermek için

  // Hasta Bilgileri
  final TextEditingController _tcController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Randevu Bilgileri
  String? _selectedHekim;
  String? _selectedTedavi;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Örnek verilen; dinamik olarak hekimler ve tedavi türleri Supabase'den çekilecek
  final List<String> _hekimler = [
    "Dt. Arda Guler",
    "Dt. Merve Aydın",
    "Dt. Kemal Sunal",
  ];
  final List<String> _tedaviler = [
    "İmplant Muayenesi",
    "Diş Taşı Temizliği",
    "Kanal Tedavisi",
    "Dolgu",
    "Diş Çekimi",
  ];

  @override
  void dispose() {
    _tcController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Bellek sızıntılarını önlemek için TextEditingController'ları temizler.
  // Tarih formatlamak için DateTime kullanıldı.
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      // Tarih seçici açılır ve kullanıcı bir tarih seçer.
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal, // Takvimdeki ana renk
              onPrimary: Colors.white, // Seçilen tarihin metin rengi
              onSurface: Colors.black, // Takvimdeki diğer metinlerin rengi
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
    // Kullanıcı bir tarih seçtiğinde _selectedDate güncellenir.
  }

  // Tarih formatlamak için TimeOfDay kullanıldı.
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
    // Kullanıcı bir saat seçtiğinde _selectedTime güncellenir.
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHekim == null ||
        _selectedTedavi == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Lütfen hekim, tedavi, tarih ve saat seçiniz."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Burada Supabase'e randevu kaydı ekleme ve loglama işlemleri yapılacak.
    await Future.delayed(const Duration(seconds: 1));
    // Simülasyon amaçlı gecikme; gerçek uygulamada Supabase işlemi burada yapılacak.
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Randevu başarıyla oluşturuldu ve loglandı."),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context); // İşlem bitince ana sayfaya döner.
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

                    _buildDropdown(
                      "Hekim Seçiniz",
                      Icons.medical_information_outlined,
                      _hekimler,
                      _selectedHekim,
                      (val) => setState(() => _selectedHekim = val),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Tedavi Türü",
                      Icons.medical_services_outlined,
                      _tedaviler,
                      _selectedTedavi,
                      (val) => setState(() => _selectedTedavi = val),
                    ),
                    const SizedBox(height: 12),

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

                    // Kaydet Butonu
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

  // _buildInput, girdi alanları için ortak bir tasarım sağlar.
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
      validator: (v) => (v == null || v.isEmpty) ? "Zorunlu" : null,
    );
  }

  // _buildDropdown, dropdown alanları için ortak bir tasarım sağlar. Hekim ve tedavi seçimleri için kullanılır.
  Widget _buildDropdown(
    String label,
    IconData icon,
    List<String> items,
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
      items: items.map((String val) {
        return DropdownMenuItem(value: val, child: Text(val));
      }).toList(),
      onChanged: onChanged,
    );
  }

  // Tarih ve saat seçicileri için ortak bir tasarım sağlar.
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
