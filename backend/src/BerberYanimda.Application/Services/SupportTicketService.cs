using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class SupportTicketService(IAppDbContext dbContext)
{
    public async Task<IReadOnlyList<SupportTicketDto>> GetUserTicketsAsync(Guid userId, CancellationToken ct)
    {
        var tickets = await dbContext.SupportTickets
            .AsNoTracking()
            .Include(x => x.Replies)
            .ThenInclude(r => r.User)
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(ct);

        return tickets.Select(MapToDto).ToList();
    }

    public async Task<SupportTicketDto> CreateAsync(Guid userId, CreateSupportTicketRequest request, CancellationToken ct)
    {
        var ticket = new SupportTicket
        {
            UserId = userId,
            Subject = request.Subject,
            Description = request.Description,
            Category = request.Category,
            Status = SupportTicketStatus.Open,
        };

        dbContext.SupportTickets.Add(ticket);
        await dbContext.SaveChangesAsync(ct);

        return MapToDto(ticket);
    }

    public async Task<SupportTicketReplyDto> AddReplyAsync(Guid userId, CreateSupportTicketReplyRequest request, bool isStaff, CancellationToken ct)
    {
        var ticket = await dbContext.SupportTickets
            .FirstOrDefaultAsync(x => x.Id == request.SupportTicketId, ct)
            ?? throw new InvalidOperationException("Destek talebi bulunamadı.");

        if (!isStaff && ticket.UserId != userId)
        {
            throw new UnauthorizedAccessException("Bu destek talebine yanıt verme yetkiniz yok.");
        }

        var reply = new SupportTicketReply
        {
            SupportTicketId = request.SupportTicketId,
            UserId = userId,
            Message = request.Message,
            IsStaffReply = isStaff,
        };

        dbContext.SupportTicketReplies.Add(reply);

        if (isStaff && ticket.Status == SupportTicketStatus.Open)
        {
            ticket.Status = SupportTicketStatus.InProgress;
        }

        await dbContext.SaveChangesAsync(ct);

        return new SupportTicketReplyDto(
            reply.Id,
            reply.Message,
            reply.IsStaffReply,
            reply.CreatedAt,
            reply.UserId,
            reply.User?.FullName
        );
    }

    private static SupportTicketDto MapToDto(SupportTicket ticket)
    {
        return new SupportTicketDto(
            ticket.Id,
            ticket.Subject,
            ticket.Description,
            ticket.Status,
            ticket.Category,
            ticket.Resolution,
            ticket.ResolvedAt,
            ticket.CreatedAt,
            ticket.UpdatedAt,
            ticket.Replies.Select(r => new SupportTicketReplyDto(
                r.Id,
                r.Message,
                r.IsStaffReply,
                r.CreatedAt,
                r.UserId,
                r.User?.FullName
            )).ToList()
        );
    }
}
