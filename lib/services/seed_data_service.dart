import '../models/profile_model.dart';
import '../models/spot_model.dart';
import '../models/restaurant_model.dart';
import '../models/discount_code_model.dart';
import '../models/guide_model.dart';
import '../models/review_model.dart';
import '../models/notification_model.dart';

class SeedDataService {
  /// Shared synthetic password for non-release demo fixtures only.
  ///
  /// Demo authentication is intentionally not a production security model.
  static const demoPassword = '123456';

  static List<ProfileModel> getInitialProfiles() => [
        ProfileModel(
          id: 'usr-tourist-1',
          email: 'tourist@livelocal.com',
          fullName: 'Alex Tan (Tourist)',
          avatarUrl:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          role: 'tourist',
        ),
        ProfileModel(
          id: 'usr-influencer-1',
          email: 'foodie@livelocal.com',
          fullName: 'KL Foodie (Creator)',
          avatarUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          role: 'influencer',
        ),
        ProfileModel(
          id: 'usr-admin-1',
          email: 'admin@livelocal.com',
          fullName: 'Admin User',
          avatarUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
          role: 'admin',
        ),
      ];

  static List<SpotModel> getInitialSpots() => [
        SpotModel(
          id: 'spot-001',
          name: 'Kek Lok Si Temple',
          category: 'Culture',
          description:
              'Sprawling Buddhist temple complex featuring the Pagoda of Rama VI and the Guanyin pavilion.',
          state: 'Pulau Pinang',
          city: 'Air Itam',
          address:
              '1000-L, Tingkat Lembah Ria 1, 11500 Ayer Itam, Pulau Pinang',
          priceRange: r'$',
          bestTime: 'Morning (8:30 AM - 11:00 AM)',
          thingsToDo: 'Visit the pagoda, Guanyin pavilion, and temple gardens',
          imageUrl:
              'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=600',
          rating: 4.8,
          reviewCount: 42,
          submittedBy: 'usr-tourist-1',
          status: 'approved',
          latitude: 5.3995,
          longitude: 100.2736,
        ),
        SpotModel(
          id: 'spot-002',
          name: 'Central Market (Pasar Seni)',
          category: 'Culture',
          description:
              'Historic Art Deco cultural landmark established in 1888, showcasing Malaysian handicrafts, batik textiles, and traditional arts.',
          state: 'Kuala Lumpur',
          city: 'Kuala Lumpur',
          address: 'Jalan Hang Kasturi, City Centre, 50050 Kuala Lumpur',
          priceRange: r'$',
          bestTime: 'Morning to late afternoon (10:00 AM - 6:00 PM)',
          thingsToDo: 'Browse Malaysian crafts, batik, and local art galleries',
          imageUrl:
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600',
          rating: 4.6,
          reviewCount: 29,
          submittedBy: 'usr-tourist-1',
          status: 'approved',
          latitude: 3.1453,
          longitude: 101.6958,
        ),
        SpotModel(
          id: 'spot-003',
          name: 'Sarawak Cultural Village',
          category: 'Culture',
          description:
              'Living museum showcasing Malaysian Borneo longhouses, traditional crafts, music, and cultural performances.',
          state: 'Sarawak',
          city: 'Santubong',
          address: 'Pantai Damai, Santubong, 93752 Kuching, Sarawak',
          priceRange: r'$$',
          bestTime: 'Cultural show times (11:30 AM / 4:00 PM)',
          thingsToDo:
              'Explore traditional longhouses and watch a cultural performance',
          imageUrl:
              'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600',
          rating: 4.7,
          reviewCount: 35,
          submittedBy: 'usr-influencer-1',
          status: 'approved',
          latitude: 1.7505,
          longitude: 110.3168,
        ),
        SpotModel(
          id: 'spot-004',
          name: 'Christ Church Melaka & Dutch Square',
          category: 'Historical',
          description:
              'The distinctive red Dutch Square is anchored by the 18th-century Christ Church and historic civic buildings.',
          state: 'Melaka',
          city: 'Melaka',
          address: 'Jalan Gereja, Bandar Hilir, 75000 Melaka',
          priceRange: r'$',
          bestTime: 'Early morning or late afternoon',
          thingsToDo: 'Explore Dutch Square and the surrounding heritage core',
          imageUrl:
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
          rating: 4.5,
          reviewCount: 18,
          submittedBy: 'usr-tourist-1',
          status: 'approved',
          latitude: 2.1944,
          longitude: 102.2492,
        ),
      ];

  static List<RestaurantModel> getInitialRestaurants() => [
        RestaurantModel(
          id: 'rest-001',
          name: 'Hameediyah Restaurant',
          address: '164A, Lebuh Campbell, 10100 George Town, Pulau Pinang',
          state: 'Pulau Pinang',
          city: 'George Town',
          cuisineType: 'Nasi Kandar / Indian Muslim',
          priceRange: r'$',
          reviewedDishes: 'Nasi Kandar, murtabak, and ayam bawang',
          influencerId: 'usr-influencer-1',
          influencerName: 'KL Foodie',
          socialMediaUrl: 'https://www.instagram.com/hameediyah/',
          coverPhotoUrl:
              'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600',
          latitude: 5.4189,
          longitude: 100.3341,
        ),
        RestaurantModel(
          id: 'rest-002',
          name: 'Restoran Hua Mui',
          address: '131, Jalan Trus, Bandar Johor Bahru, 80000 Johor Bahru',
          state: 'Johor',
          city: 'Johor Bahru',
          cuisineType: 'Hainanese',
          priceRange: r'$$',
          reviewedDishes: 'Hainanese chicken chop, kaya toast, and kopi',
          influencerId: 'usr-influencer-1',
          influencerName: 'Penang Eats',
          socialMediaUrl: 'https://www.instagram.com/restoranhuamui/',
          coverPhotoUrl:
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
          latitude: 1.4573,
          longitude: 103.7642,
        ),
        RestaurantModel(
          id: 'rest-003',
          name: 'Choon Hui Cafe',
          address: '34, Jalan Ban Hock, 93100 Kuching, Sarawak',
          state: 'Sarawak',
          city: 'Kuching',
          cuisineType: 'Sarawak / Kopitiam',
          priceRange: r'$',
          reviewedDishes: 'Sarawak laksa, kolo mee, and kaya toast',
          influencerId: 'usr-influencer-1',
          influencerName: 'Foodie Explorer MY',
          socialMediaUrl: 'https://www.instagram.com/choonhuicafe/',
          coverPhotoUrl:
              'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=600',
          latitude: 1.5517,
          longitude: 110.3546,
        ),
      ];

  static List<DiscountCodeModel> getInitialDiscountCodes() => [
        DiscountCodeModel(
          id: 'disc-001',
          restaurantId: 'rest-001',
          code: 'LIVELOCAL10',
          description:
              'Get 10% OFF any Char Kuey Teow order when showing LiveLocal App',
          expiryDate: DateTime.now().add(const Duration(days: 60)),
          createdBy: 'usr-influencer-1',
        ),
        DiscountCodeModel(
          id: 'disc-002',
          restaurantId: 'rest-002',
          code: 'KLFOODIESPECIAL',
          description:
              'Free Sirap Bandung drink with any Nasi Kandar set purchase',
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          createdBy: 'usr-influencer-1',
        ),
      ];

  static List<GuideModel> getInitialGuides() => [
        GuideModel(
          id: 'guide-001',
          title: 'Kuala Lumpur Historic Colonial Core & River Trail',
          locationName: 'Merdeka Square',
          state: 'Kuala Lumpur',
          routeOverview:
              'Discover Kuala Lumpur’s founding river confluence and its surrounding civic, religious, and cultural landmarks.',
          stops: [
            'Dataran Merdeka (Independence Square)',
            'Sultan Abdul Samad Building',
            'Masjid Jamek River of Life',
            'Central Market (Pasar Seni)'
          ],
          walkingSequence: [
            'Begin at the Merdeka Square flagpole',
            'Cross to the Sultan Abdul Samad heritage frontage',
            'Continue to the Klang and Gombak river confluence',
            'Finish at Central Market’s local art and craft stalls'
          ],
          estimatedDuration: '2.5 hours',
          status: 'approved',
        ),
        GuideModel(
          id: 'guide-002',
          title: 'Ipoh Old Town Heritage & Coffee Crawl',
          locationName: 'Ipoh Old Town',
          state: 'Perak',
          routeOverview:
              'Follow Ipoh’s documented old-town heritage trail through civic landmarks, historic lanes, and preserved shophouses.',
          stops: [
            'Ipoh Town Hall & High Court',
            'Birch Memorial Clock Tower',
            'Concubine Lane',
            'Ipoh Railway Station'
          ],
          walkingSequence: [
            '1. Start at Concubine Lane at 9:00 AM before crowd arrives',
            '2. Enjoy authentic White Coffee at Sin Yoon Loong',
            '3. Walk through mural alleys toward Railway Gardens',
            '4. Enjoy famous Egg Tarts at Nam Heong'
          ],
          estimatedDuration: '4 Hours',
          status: 'approved',
        ),
      ];

  static List<ReviewModel> getInitialReviews() => [
        ReviewModel(
          id: 'rev-001',
          spotId: 'spot-001',
          userId: 'usr-tourist-1',
          userName: 'Alex Tan',
          rating: 5.0,
          comment:
              'Super authentic Hainanese coffee! The toast was perfectly crispy and charcoal grilled. A true hidden gem.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ReviewModel(
          id: 'rev-002',
          restaurantId: 'rest-001',
          userId: 'usr-tourist-1',
          userName: 'Alex Tan',
          rating: 4.5,
          comment:
              'Used the LIVELOCAL10 discount code here and got 10% off! The duck egg char kuey teow had amazing wok hei.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

  static List<NotificationModel> getInitialNotifications() => [
        NotificationModel(
          id: 'notif-001',
          userId: 'usr-tourist-1',
          title: 'New Local Spot Approved!',
          message: 'Chop Seng Hin Kopitiam in Penang is now live on LiveLocal.',
          type: 'spot_approved',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        NotificationModel(
          id: 'notif-002',
          userId: 'usr-tourist-1',
          title: 'Exclusive Discount Code Alert',
          message:
              'KL Foodie added a 10% discount code for Ah Hock Hawker CKT in Penang!',
          type: 'discount_alert',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
}
