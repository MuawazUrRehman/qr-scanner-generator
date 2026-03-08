import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_scanner/features/result/result_screen.dart';

class CreateQrScreen extends StatefulWidget {
  const CreateQrScreen({super.key});

  @override
  State<CreateQrScreen> createState() => _CreateQrScreenState();
}

class _CreateQrScreenState extends State<CreateQrScreen> {
  QrType? _selectedType;
  String? _overrideTitle;

  // Controllers
  final _contentController = TextEditingController(); // For Clipboard, Text, URL
  
  // Contact / MyQR
  final _nameController = TextEditingController();
  final _orgController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();

  // SMS
  final _smsPhoneController = TextEditingController();
  final _smsMessageController = TextEditingController();

  // Geo
  final _latController = TextEditingController();
  final _longController = TextEditingController();
  final _queryController = TextEditingController();

  // WiFi
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  String _encryption = 'WPA'; // WPA, WEP, None
  bool _isHidden = false;

  // Calendar
  final _explanationController = TextEditingController(); // Event Name
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
  bool _isAllDay = false;

  @override
  void dispose() {
    _contentController.dispose();
    _nameController.dispose();
    _orgController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    _smsPhoneController.dispose();
    _smsMessageController.dispose();
    _latController.dispose();
    _longController.dispose();
    _queryController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _explanationController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ==========================================
  // UI CODES (Build Methods)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (_selectedType == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.purple.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildGrid(),
            ],
          ),
        ),
      );
    }

    // If type selected, show Form
    final title = _overrideTitle ?? _getTypeTitle(_selectedType!);

    return PopScope(
      canPop: false, // Prevent default pop when form is open
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _selectedType = null;
          _overrideTitle = null;
          _contentController.clear();
        });
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.purple.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedType = null;
                _overrideTitle = null;
                _contentController.clear();
              });
            },
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white, size: 30),
              onPressed: _generateQr,
            )
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header: Icon + Title (Left Aligned)
              Row(
                   mainAxisAlignment: MainAxisAlignment.start,
                   children: [
                      Icon(_getTypeIcon(_selectedType!), size: 40, color: Colors.blue),
                      const SizedBox(width: 15),
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   ],
              ),
              if (_overrideTitle == 'My QR') ...[
                 const SizedBox(height: 10),
                 Text(
                   "Create your personal QR code with your contact details. Share your digital business card instantly with anyone, anywhere.",
                   style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                 ),
              ],
              const SizedBox(height: 30),
              _buildForm(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() { 
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildListItem(Icons.content_paste, 'Clipboard', onTap: _selectClipboard, color: Colors.orange),
        const SizedBox(height: 10),
        _buildListItem(Icons.language, 'URL', type: QrType.url, color: Colors.blue),
        const SizedBox(height: 10),
        _buildListItem(Icons.text_fields, 'Text', type: QrType.text, color: Colors.black),
        const SizedBox(height: 10),
        _buildListItem(Icons.person, 'Contact', type: QrType.contact, color: Colors.purple),
        const SizedBox(height: 10),
        _buildListItem(Icons.email, 'Email', type: QrType.email, color: Colors.red),
        const SizedBox(height: 10),
        _buildListItem(Icons.sms, 'SMS', type: QrType.sms, color: Colors.cyan),
        const SizedBox(height: 10),
        _buildListItem(Icons.location_on, 'Location', type: QrType.geo, color: Colors.green),
        const SizedBox(height: 10),
        _buildListItem(Icons.phone, 'Phone', type: QrType.phone, color: Colors.pink),
        const SizedBox(height: 10),
        _buildListItem(Icons.calendar_today, 'Calendar', type: QrType.calendar, color: Colors.indigo),
        const SizedBox(height: 10),
        _buildListItem(Icons.wifi, 'WiFi', type: QrType.wifi, color: Colors.teal),
        const SizedBox(height: 10),
        _buildListItem(Icons.qr_code_2, 'My QR', onTap: () {
            setState(() {
              _selectedType = QrType.contact;
              _overrideTitle = 'My QR';
            });
        }, color: Colors.deepPurple),
      ],
    );
  }

  Widget _buildListItem(IconData icon, String label, {QrType? type, VoidCallback? onTap, Color color = Colors.blue}) {
    return GestureDetector(
      onTap: onTap ?? () => _onTypeSelected(type!),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
             BoxShadow(
               color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.grey.shade200, 
               blurRadius: 10, 
               offset: const Offset(0,5)
             )
          ]
        ),
        child: Row(
          children: [
            Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
               child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    switch (_selectedType) {
      case QrType.url:
        return _buildGenericInput(_contentController, 'Enter URL', Icons.link);
      case QrType.text:
        return _buildGenericInput(_contentController, 'Enter Text', Icons.text_fields, maxLines: 5);
      case QrType.contact:
        return _buildContactForm();
      case QrType.email:
        return _buildEmailForm();
      case QrType.sms:
        return _buildSmsForm();
      case QrType.geo:
        return _buildGeoForm();
      case QrType.phone:
        return _buildGenericInput(_phoneController, 'Enter Phone Number', Icons.phone, keyboardType: TextInputType.phone);
      case QrType.calendar:
        return _buildCalendarForm();
      case QrType.wifi:
        return _buildWifiForm();
      default:
        return const SizedBox();
    }
  }

  Widget _buildGenericInput(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: maxLines,
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
      textAlignVertical: TextAlignVertical.top, // Icon aligns to top as field grows
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Adjust padding
      ),
    );
  }

  Widget _buildContactForm() {
    return Column(
      children: [
        _buildGenericInput(_nameController, 'Full Name', Icons.person),
        const SizedBox(height: 15),
        _buildGenericInput(_orgController, 'Organization', Icons.business),
        const SizedBox(height: 15),
        _buildGenericInput(_addressController, 'Address', Icons.location_on, maxLines: 5), // Allow growth
        const SizedBox(height: 15),
        _buildGenericInput(_phoneController, 'Phone', Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 15),
        _buildGenericInput(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 15),
        _buildGenericInput(_noteController, 'Notes', Icons.note, maxLines: 5), // Allow growth
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
       children: [
          _buildGenericInput(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
       ],
    );
  }

  Widget _buildSmsForm() {
    return Column(
      children: [
        _buildGenericInput(_smsPhoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 15),
        _buildGenericInput(_smsMessageController, 'Message', Icons.message, maxLines: 5),
      ],
    );
  }

  Widget _buildGeoForm() {
    return Column(
      children: [
        Row(
           children: [
             Expanded(child: _buildGenericInput(_latController, 'Latitude', Icons.map, keyboardType: TextInputType.number)),
             const SizedBox(width: 10),
             Expanded(child: _buildGenericInput(_longController, 'Longitude', Icons.map, keyboardType: TextInputType.number)),
           ],
        ),
        const SizedBox(height: 15),
        const Text("- OR -", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 15),
        _buildGenericInput(_queryController, 'Query (Address/Place)', Icons.search),
      ],
    );
  }

  Widget _buildWifiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         _buildGenericInput(_ssidController, 'Network Name (SSID)', Icons.wifi),
         const SizedBox(height: 15),
         _buildGenericInput(_passwordController, 'Password', Icons.lock, keyboardType: TextInputType.visiblePassword),
         const SizedBox(height: 20),
         const Text("Encryption", style: TextStyle(fontWeight: FontWeight.bold)),
         const SizedBox(height: 10),
         Row(
           children: [
              _buildRadio('WPA'),
              _buildRadio('WEP'),
              _buildRadio('None'),
           ],
         ),
         CheckboxListTile(
            title: const Text("Hidden Network"),
            value: _isHidden,
            onChanged: (val) => setState(() => _isHidden = val!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
         )
      ],
    );
  }

  Widget _buildRadio(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _encryption,
          onChanged: (val) => setState(() => _encryption = val!),
        ),
        Text(value),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildCalendarForm() {
     final dateFormat = DateFormat('yyyy-MM-dd');
     final timeFormat = DateFormat('HH:mm');

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          _buildGenericInput(_explanationController, 'Event Name', Icons.event),
          const SizedBox(height: 20),
          
          const Text("Start", style: TextStyle(color: Colors.grey)),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                   final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                   if(d != null) setState(() => _startDate = d);
                },
                child: Text(dateFormat.format(_startDate)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                   final t = await showTimePicker(context: context, initialTime: _startTime);
                   if(t != null) setState(() => _startTime = t);
                },
                child: Text(_startTime.format(context)),
              ),
            ],
          ),
          Divider(),
          const Text("End", style: TextStyle(color: Colors.grey)),
           Opacity(
             opacity: _isAllDay ? 0.5 : 1.0,
             child: AbsorbPointer(
               absorbing: _isAllDay,
               child: Row(
               children: [
                 TextButton(
                   onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if(d != null) setState(() => _endDate = d);
                   },
                   child: Text(dateFormat.format(_endDate)),
                 ),
                 const Spacer(),
                 TextButton(
                   onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: _endTime);
                      if(t != null) setState(() => _endTime = t);
                   },
                   child: Text(_endTime.format(context)),
                 ),
               ],
             ),
             ),
           ),
           CheckboxListTile(
             title: const Text("All Day Event"),
             value: _isAllDay,
             onChanged: (val) => setState(() => _isAllDay = val!),
             controlAffinity: ListTileControlAffinity.leading,
             contentPadding: EdgeInsets.zero,
           ),
           const SizedBox(height: 10),
           _buildGenericInput(_locationController, 'Location', Icons.location_on),
           const SizedBox(height: 15),
           _buildGenericInput(_descriptionController, 'Description', Icons.description, maxLines: 5), // Allow growth
       ],
     );
  }

   // ==========================================
   // FUNCTIONALITY / LOGIC
   // ==========================================

  void _onTypeSelected(QrType type) {
    setState(() {
      _selectedType = type;
      _overrideTitle = null;
    });
  }

  // Helper for Clipboard Action
  void _selectClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    setState(() {
      _selectedType = QrType.text; 
      _overrideTitle = 'Clipboard';
      _contentController.text = data?.text ?? '';
    });
  }

  String _getTypeTitle(QrType type) {
     if (_overrideTitle != null) return _overrideTitle!;
     switch(type) {
       case QrType.url: return 'Website';
       case QrType.wifi: return 'WiFi';
       case QrType.contact: return 'Contact';
       case QrType.email: return 'Email';
       case QrType.sms: return 'SMS';
       case QrType.geo: return 'Location';
       case QrType.phone: return 'Telephone';
       case QrType.calendar: return 'Calendar';
       case QrType.text: return 'Text'; 
       default: return 'Create QR';
     }
  }

  IconData _getTypeIcon(QrType type) {
     switch(type) {
       case QrType.url: return Icons.language;
       case QrType.wifi: return Icons.wifi;
       case QrType.contact: return Icons.person;
       case QrType.email: return Icons.email;
       case QrType.sms: return Icons.sms;
       case QrType.geo: return Icons.location_on;
       case QrType.phone: return Icons.phone;
       case QrType.calendar: return Icons.calendar_today;
       case QrType.text: return Icons.text_fields;
       default: return Icons.qr_code;
     }
  }

  void _generateQr() {
    String data = '';
    
    switch (_selectedType) {
      case QrType.url:
      case QrType.text:
       data = _contentController.text;
       break;
      
      case QrType.contact:
         data = 'BEGIN:VCARD\nVERSION:3.0\nN:${_nameController.text}\nORG:${_orgController.text}\nTEL:${_phoneController.text}\nEMAIL:${_emailController.text}\nADR:${_addressController.text}\nNOTE:${_noteController.text}\nEND:VCARD';
         break;

      case QrType.email:
        data = 'mailto:${_emailController.text}';
        break;

      case QrType.sms:
        data = 'smsto:${_smsPhoneController.text}:${_smsMessageController.text}';
        break;

      case QrType.geo:
        if (_queryController.text.isNotEmpty) {
             data = 'geo:0,0?q=${_queryController.text}';
        } else {
             data = 'geo:${_latController.text},${_longController.text}';
        }
        break;

      case QrType.phone:
        data = 'tel:${_phoneController.text}';
        break;

      case QrType.wifi:
        data = 'WIFI:T:$_encryption;S:${_ssidController.text};P:${_passwordController.text};${_isHidden ? 'H:true;' : ''};';
        break;

      case QrType.calendar:
         final startDt = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
         final endDt = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);
         final formatter = DateFormat("yyyyMMdd'T'HHmmss");
         
         data = 'BEGIN:VEVENT\nSUMMARY:${_explanationController.text}\nDTSTART:${formatter.format(startDt)}\nDTEND:${formatter.format(endDt)}\nLOCATION:${_locationController.text}\nDESCRIPTION:${_descriptionController.text}\nEND:VEVENT';
         break;
         
      default:
        data = _contentController.text;
    }

    if (data.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ResultScreen(code: data, onClose: () {})));
    }
  }
}
