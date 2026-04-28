using BerberYanimda.Domain;

namespace BerberYanimda.Application.DTOs;

public sealed record SupportTicketDto(
    Guid Id,
    string Subject,
    string Description,
    SupportTicketStatus Status,
    string? Category,
    string? Resolution,
    DateTime? ResolvedAt,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    List<SupportTicketReplyDto> Replies
);

public sealed record SupportTicketReplyDto(
    Guid Id,
    string Message,
    bool IsStaffReply,
    DateTime CreatedAt,
    Guid? UserId,
    string? UserName
);

public sealed record CreateSupportTicketRequest(
    string Subject,
    string Description,
    string? Category
);

public sealed record CreateSupportTicketReplyRequest(
    Guid SupportTicketId,
    string Message
);
