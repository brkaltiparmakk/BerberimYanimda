import 'package:berber_yanimda/src/data/models.dart';

abstract final class MockData {
  static final services = [
    const BarberService(
      id: 'svc-hair',
      name: 'Saç Kesimi',
      durationMinutes: 30,
      price: 250,
    ),
    const BarberService(
      id: 'svc-beard',
      name: 'Sakal Tıraşı',
      durationMinutes: 20,
      price: 150,
    ),
    const BarberService(
      id: 'svc-skin',
      name: 'Cilt Bakımı',
      durationMinutes: 40,
      price: 300,
    ),
    const BarberService(
      id: 'svc-combo',
      name: 'Saç + Sakal',
      durationMinutes: 50,
      price: 400,
    ),
  ];

  static final staff = [
    const Staff(
      id: 'staff-mehmet',
      name: 'Mehmet Usta',
      expertise: 'Saç Kesimi Uzmanı',
      rating: 4.9,
      isAvailableToday: true,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
    ),
    const Staff(
      id: 'staff-ali',
      name: 'Ali Yıldız',
      expertise: 'Sakal Uzmanı',
      rating: 4.8,
      isAvailableToday: true,
      avatarUrl:
          'https://images.unsplash.com/photo-1566492031773-4f4e44671857?auto=format&fit=crop&w=200&q=80',
    ),
    const Staff(
      id: 'staff-emre',
      name: 'Emre Kaya',
      expertise: 'Klasik Kesim',
      rating: 4.7,
      isAvailableToday: true,
      avatarUrl: '',
    ),
  ];

  static final barbers = [
    Barber(
      id: 'modern',
      name: 'Modern Barber',
      district: 'Kadıköy',
      city: 'İstanbul',
      rating: 4.8,
      reviewCount: 120,
      distanceKm: 1.2,
      startingPrice: 250,
      isAvailableToday: true,
      imageUrl:
          'https://images.unsplash.com/photo-1512690459411-b9245aed614b?auto=format&fit=crop&w=900&q=80',
      isFavorite: true,
      description:
          'Modern Barber, profesyonel ekibiyle şehirde en iyi hizmeti sunar.',
      address: 'Moda Cad. No: 18 Kadıköy, İstanbul',
      services: services,
      staff: staff,
    ),
    Barber(
      id: 'kingsman',
      name: 'The Kingsman',
      district: 'Beşiktaş',
      city: 'İstanbul',
      rating: 4.7,
      reviewCount: 98,
      distanceKm: 2.1,
      startingPrice: 300,
      isAvailableToday: true,
      imageUrl:
          'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=900&q=80',
      isFavorite: false,
      description:
          'Klasik berber kültürünü modern randevu deneyimiyle birleştirir.',
      address: 'Akaretler Sıraevler No: 7 Beşiktaş, İstanbul',
      services: services.take(3).toList(),
      staff: staff.take(2).toList(),
    ),
    Barber(
      id: 'vision',
      name: 'Salon Vizyon',
      district: 'Ataşehir',
      city: 'İstanbul',
      rating: 4.6,
      reviewCount: 76,
      distanceKm: 2.8,
      startingPrice: 200,
      isAvailableToday: true,
      imageUrl:
          'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=900&q=80',
      isFavorite: false,
      description: 'Hızlı, temiz ve randevu saatine sadık mahalle berberi.',
      address: 'Atatürk Mah. No: 22 Ataşehir, İstanbul',
      services: services,
      staff: staff,
    ),
  ];

  static List<TimeSlot> slots() => [
    const TimeSlot(startTime: '09:00', endTime: '09:50', isAvailable: true),
    const TimeSlot(startTime: '09:30', endTime: '10:20', isAvailable: true),
    const TimeSlot(startTime: '10:00', endTime: '10:50', isAvailable: false),
    const TimeSlot(startTime: '10:30', endTime: '11:20', isAvailable: true),
    const TimeSlot(startTime: '11:00', endTime: '11:50', isAvailable: true),
    const TimeSlot(startTime: '13:30', endTime: '14:20', isAvailable: true),
    const TimeSlot(startTime: '14:30', endTime: '15:20', isAvailable: true),
    const TimeSlot(startTime: '16:00', endTime: '16:50', isAvailable: true),
  ];

  static List<Appointment> appointments() => [
    Appointment(
      id: 'appt-1',
      barberName: 'Modern Barber',
      barberImageUrl: barbers.first.imageUrl,
      dateTime: DateTime(2026, 4, 25, 10, 30),
      endTime: DateTime(2026, 4, 25, 11, 20),
      staffName: 'Mehmet Usta',
      services: const ['Saç Kesimi', 'Sakal Tıraşı'],
      totalPrice: 400,
      status: AppointmentStatus.confirmed,
    ),
  ];
}
