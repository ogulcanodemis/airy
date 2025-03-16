import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gizlilik Politikası',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Son Güncelleme: 15 Mart 2024',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Giriş',
              'Bu gizlilik politikası, Airy uygulamasını kullanırken toplanan, işlenen ve saklanan kişisel verilerinizle ilgili bilgileri içerir. Uygulamayı kullanarak, bu politikada belirtilen uygulamaları kabul etmiş olursunuz.',
            ),
            _buildSection(
              'Topladığımız Veriler',
              '''Uygulamamız aşağıdaki verileri toplar ve işler:

1. Konum Bilgileri: Bulunduğunuz yerdeki hava kalitesi verilerini sağlamak için coğrafi konum bilgilerinizi kullanırız.

2. Kullanıcı Hesap Bilgileri: E-posta adresiniz ve kullanıcı adınız gibi hesap oluşturma ve oturum açma için gerekli bilgiler.

3. Uygulama Kullanım Verileri: Uygulama içindeki etkileşimleriniz ve tercihleriniz.

4. Cihaz Bilgileri: İşletim sistemi, cihaz modeli ve uygulama versiyonu gibi teknik bilgiler.''',
            ),
            _buildSection(
              'Verilerin Kullanımı',
              '''Topladığımız verileri aşağıdaki amaçlar için kullanırız:

1. Hava kalitesi bilgilerini sağlamak ve kişiselleştirilmiş uyarılar göndermek.

2. Uygulamanın işlevselliğini ve performansını iyileştirmek.

3. Kullanıcı hesaplarını yönetmek ve güvenliği sağlamak.

4. Yasal yükümlülüklere uymak.''',
            ),
            _buildSection(
              'Veri Paylaşımı',
              '''Verilerinizi aşağıdaki durumlarda üçüncü taraflarla paylaşabiliriz:

1. Hava kalitesi verilerini sağlayan API servisleri (WAQI API).

2. Bulut depolama ve analitik hizmetleri sağlayan iş ortaklarımız.

3. Yasal zorunluluk durumunda yetkili kurumlar.

Verilerinizi pazarlama amaçlı olarak üçüncü taraflarla paylaşmıyoruz.''',
            ),
            _buildSection(
              'Veri Güvenliği',
              'Verilerinizi korumak için endüstri standardı güvenlik önlemleri uyguluyoruz. Bununla birlikte, internet üzerinden hiçbir veri iletiminin veya elektronik depolamanın %100 güvenli olmadığını unutmayın.',
            ),
            _buildSection(
              'Çocukların Gizliliği',
              'Uygulamamız 13 yaşın altındaki çocuklardan bilerek veri toplamaz. Eğer 13 yaşın altındaki bir çocuğun kişisel verilerini topladığımızı fark ederseniz, lütfen bizimle iletişime geçin.',
            ),
            _buildSection(
              'Politika Değişiklikleri',
              'Bu gizlilik politikasını zaman zaman güncelleyebiliriz. Değişiklikler yapıldığında, uygulama içinde bildirim yayınlayacağız ve politikanın güncellenmiş versiyonunu burada yayınlayacağız.',
            ),
            _buildSection(
              'İletişim',
              'Bu gizlilik politikası hakkında sorularınız veya endişeleriniz varsa, lütfen info@appdesignhouse.com adresinden bizimle iletişime geçin.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 