using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BerberYanimda.Infrastructure.Persistence;

public static class SeedData
{
    public static async Task InitializeAsync(IServiceProvider services, CancellationToken ct = default)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        if (await db.Users.AnyAsync(ct))
        {
            return;
        }

        var password = scope.ServiceProvider.GetRequiredService<IPasswordService>();

        var admin = CreateUser("Sistem Admin", "+905550000000", UserRole.Admin, password, "Admin123!");
        var customer = CreateUser("Burak Altıparmak", "+905551112233", UserRole.Customer, password, "Test1234!");
        var owner = CreateUser("Modern Barber Sahibi", "+905552223344", UserRole.BarberOwner, password, "Owner123!");
        var staffUser = CreateUser("Mehmet Usta", "+905553334455", UserRole.Staff, password, "Staff123!");

        var modern = new BarberShop
        {
            OwnerUserId = owner.Id,
            Name = "Modern Barber",
            Description = "Profesyonel ekibiyle şehirde en iyi hizmeti sunar.",
            PhoneNumber = "+902121112233",
            City = "İstanbul",
            District = "Kadıköy",
            Address = "Moda Cad. No: 18 Kadıköy, İstanbul",
            Latitude = 40.9876543m,
            Longitude = 29.0271234m,
            CoverImageUrl = "https://images.unsplash.com/photo-1512690459411-b9245aed614b?auto=format&fit=crop&w=900&q=80",
            AverageRating = 4.8m,
            ReviewCount = 120,
            StartingPrice = 250,
            IsApproved = true
        };

        var kingsman = new BarberShop
        {
            OwnerUserId = owner.Id,
            Name = "The Kingsman",
            Description = "Klasik berber kültürünü modern randevu deneyimiyle birleştirir.",
            PhoneNumber = "+902124445566",
            City = "İstanbul",
            District = "Beşiktaş",
            Address = "Akaretler Sıraevler No: 7 Beşiktaş, İstanbul",
            Latitude = 41.0434567m,
            Longitude = 29.0054321m,
            CoverImageUrl = "https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=900&q=80",
            AverageRating = 4.7m,
            ReviewCount = 98,
            StartingPrice = 300,
            IsApproved = true
        };

        var pending = new BarberShop
        {
            OwnerUserId = owner.Id,
            Name = "Yeni Semt Berberi",
            Description = "Admin onayı bekleyen demo işletme.",
            City = "İstanbul",
            District = "Ataşehir",
            Address = "Atatürk Mah. No: 22 Ataşehir, İstanbul",
            StartingPrice = 200,
            IsApproved = false
        };

        var haircut = new BarberService { BarberShopId = modern.Id, Name = "Saç Kesimi", DurationMinutes = 30, Price = 250 };
        var beard = new BarberService { BarberShopId = modern.Id, Name = "Sakal Tıraşı", DurationMinutes = 20, Price = 150 };
        var skin = new BarberService { BarberShopId = modern.Id, Name = "Cilt Bakımı", DurationMinutes = 40, Price = 300 };
        var combo = new BarberService { BarberShopId = modern.Id, Name = "Saç + Sakal", DurationMinutes = 50, Price = 400 };

        var kingsHaircut = new BarberService { BarberShopId = kingsman.Id, Name = "Saç Kesimi", DurationMinutes = 30, Price = 300 };
        var kingsBeard = new BarberService { BarberShopId = kingsman.Id, Name = "Sakal Tıraşı", DurationMinutes = 20, Price = 180 };

        var mehmet = new StaffMember
        {
            BarberShopId = modern.Id,
            UserId = staffUser.Id,
            FullName = "Mehmet Usta",
            Expertise = "Saç Kesimi Uzmanı",
            AvatarUrl = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80",
            AverageRating = 4.9m
        };

        var ali = new StaffMember
        {
            BarberShopId = modern.Id,
            FullName = "Ali Yıldız",
            Expertise = "Sakal Uzmanı",
            AvatarUrl = "https://images.unsplash.com/photo-1566492031773-4f4e44671857?auto=format&fit=crop&w=200&q=80",
            AverageRating = 4.8m
        };

        var emre = new StaffMember
        {
            BarberShopId = kingsman.Id,
            FullName = "Emre Kaya",
            Expertise = "Klasik Kesim",
            AverageRating = 4.7m
        };

        var appointment = new Appointment
        {
            CustomerUserId = customer.Id,
            BarberShopId = modern.Id,
            StaffMemberId = mehmet.Id,
            AppointmentDate = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(1),
            StartTime = new TimeOnly(10, 30),
            EndTime = new TimeOnly(11, 20),
            TotalDurationMinutes = 50,
            TotalPrice = 400,
            Status = AppointmentStatus.Confirmed,
            Services =
            [
                new AppointmentService { BarberServiceId = haircut.Id, ServiceName = haircut.Name, DurationMinutes = haircut.DurationMinutes, Price = haircut.Price },
                new AppointmentService { BarberServiceId = beard.Id, ServiceName = beard.Name, DurationMinutes = beard.DurationMinutes, Price = beard.Price }
            ]
        };

        db.Users.AddRange(admin, customer, owner, staffUser);
        db.BarberShops.AddRange(modern, kingsman, pending);
        db.BarberServices.AddRange(haircut, beard, skin, combo, kingsHaircut, kingsBeard);
        db.StaffMembers.AddRange(mehmet, ali, emre);
        db.StaffServices.AddRange(
            Link(mehmet, haircut),
            Link(mehmet, beard),
            Link(mehmet, combo),
            Link(ali, beard),
            Link(ali, skin),
            Link(emre, kingsHaircut),
            Link(emre, kingsBeard));
        db.WorkingHours.AddRange(CreateWeek(modern.Id).Concat(CreateWeek(kingsman.Id)));
        db.WorkingHours.AddRange(CreateWeek(modern.Id, mehmet.Id).Concat(CreateWeek(modern.Id, ali.Id)).Concat(CreateWeek(kingsman.Id, emre.Id)));
        db.FavoriteBarberShops.Add(new FavoriteBarberShop { UserId = customer.Id, BarberShopId = modern.Id });
        db.Appointments.Add(appointment);
        db.Payments.Add(new Payment { AppointmentId = appointment.Id, CustomerUserId = customer.Id, Amount = appointment.TotalPrice });
        db.Notifications.Add(new Notification
        {
            UserId = customer.Id,
            Title = "Randevunuz onaylandı",
            Message = "Modern Barber randevunuz onaylandı.",
            Type = NotificationType.AppointmentConfirmed
        });

        await db.SaveChangesAsync(ct);
    }

    private static User CreateUser(string fullName, string phone, UserRole role, IPasswordService password, string rawPassword)
    {
        var user = new User
        {
            FullName = fullName,
            PhoneNumber = phone,
            Role = role,
            IsPhoneVerified = true,
            IsActive = true
        };
        user.PasswordHash = password.HashPassword(user, rawPassword);
        return user;
    }

    private static StaffService Link(StaffMember staff, BarberService service) =>
        new() { StaffMemberId = staff.Id, BarberServiceId = service.Id };

    private static IEnumerable<WorkingHour> CreateWeek(Guid barberShopId, Guid? staffMemberId = null)
    {
        for (var day = 1; day <= 6; day++)
        {
            yield return new WorkingHour
            {
                BarberShopId = barberShopId,
                StaffMemberId = staffMemberId,
                DayOfWeek = day,
                StartTime = new TimeOnly(9, 0),
                EndTime = new TimeOnly(20, 0)
            };
        }

        yield return new WorkingHour
        {
            BarberShopId = barberShopId,
            StaffMemberId = staffMemberId,
            DayOfWeek = 7,
            StartTime = new TimeOnly(10, 0),
            EndTime = new TimeOnly(18, 0)
        };
    }
}
