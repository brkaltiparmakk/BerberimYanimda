namespace BerberYanimda.Domain;

public enum UserRole
{
    Customer,
    BarberOwner,
    Staff,
    Admin
}

public enum AppointmentStatus
{
    Pending,
    Confirmed,
    Upcoming,
    Completed,
    Cancelled,
    Rejected,
    NoShow
}

public enum PaymentStatus
{
    Pending,
    Paid,
    Failed,
    Refunded,
    Cancelled
}

public enum PaymentMethod
{
    PayAtBarber,
    Online,
    OnlineCard,
    Wallet
}

public enum NotificationType
{
    AppointmentConfirmed,
    AppointmentReminder,
    AppointmentCancelled,
    AppointmentRejected,
    PaymentSuccess,
    PaymentFailed,
    Campaign,
    System
}

public enum SupportTicketStatus
{
    Open,
    InProgress,
    Resolved,
    Closed
}
