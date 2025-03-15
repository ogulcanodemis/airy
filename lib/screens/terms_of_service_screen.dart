import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Koşulları'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kullanım Koşulları',
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
              'Bu kullanım koşulları, Hava Kalitesi uygulamasını kullanımınızı düzenleyen şartları ve koşulları belirler. Uygulamayı kullanarak, bu koşulları kabul etmiş olursunuz.',
            ),
            _buildSection(
              'Hesap Oluşturma ve Güvenlik',
              '''1. Uygulamamızı kullanmak için bir hesap oluşturmanız gerekebilir.

2. Hesap bilgilerinizin gizliliğini korumak ve hesabınızla gerçekleştirilen tüm etkinliklerden sorumlu olmak sizin sorumluluğunuzdadır.

3. Hesabınızın yetkisiz kullanımından şüpheleniyorsanız, derhal bize bildirmelisiniz.''',
            ),
            _buildSection(
              'Kullanım Lisansı',
              '''1. Size, bu uygulamayı kişisel ve ticari olmayan amaçlarla kullanmanız için sınırlı, münhasır olmayan, devredilemez bir lisans veriyoruz.

2. Bu lisans, uygulamayı kopyalama, değiştirme, dağıtma, satma, kiralama veya alt lisanslama hakkını içermez.''',
            ),
            _buildSection(
              'Kullanıcı Davranışı',
              '''Uygulamayı kullanırken aşağıdaki davranışlardan kaçınmayı kabul edersiniz:

1. Yasalara aykırı, zararlı, tehdit edici, taciz edici, karalayıcı veya başka şekilde uygunsuz içerik oluşturmak veya paylaşmak.

2. Uygulamanın normal işleyişini engellemek veya bozmak.

3. Uygulamaya yetkisiz erişim sağlamaya çalışmak.

4. Diğer kullanıcıların gizliliğini ihlal etmek.''',
            ),
            _buildSection(
              'Fikri Mülkiyet',
              '''1. Uygulama ve içeriği, telif hakkı, ticari marka ve diğer fikri mülkiyet hakları ile korunmaktadır.

2. Uygulamadaki hiçbir içeriği, önceden yazılı izin almadan kopyalayamaz, değiştiremez veya dağıtamazsınız.''',
            ),
            _buildSection(
              'Sorumluluk Reddi',
              '''1. Uygulama "olduğu gibi" ve "mevcut olduğu şekilde" sunulmaktadır, herhangi bir garanti olmaksızın.

2. Hava kalitesi verileri, üçüncü taraf kaynaklardan (WAQI API) alınmaktadır ve doğruluğu garanti edilmemektedir.

3. Uygulamanın kullanımından kaynaklanan herhangi bir zarar veya kayıptan sorumlu değiliz.''',
            ),
            _buildSection(
              'Değişiklikler',
              '''1. Bu kullanım koşullarını herhangi bir zamanda değiştirme hakkını saklı tutarız.

2. Değişiklikler, uygulamada yayınlandıktan sonra geçerli olacaktır.

3. Değişikliklerden sonra uygulamayı kullanmaya devam etmeniz, güncellenmiş koşulları kabul ettiğiniz anlamına gelir.''',
            ),
            _buildSection(
              'Fesih',
              'Bu koşulları ihlal etmeniz durumunda, hesabınızı askıya alma veya sonlandırma hakkını saklı tutarız.',
            ),
            _buildSection(
              'İletişim',
              'Bu kullanım koşulları hakkında sorularınız veya endişeleriniz varsa, lütfen info@appdesignhouse.com adresinden bizimle iletişime geçin.',
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