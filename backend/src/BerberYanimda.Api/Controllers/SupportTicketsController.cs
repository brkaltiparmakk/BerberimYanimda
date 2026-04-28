using BerberYanimda.Api.Extensions;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Authorize(Roles = nameof(UserRole.Customer))]
[Route("api/v1/support-tickets")]
public sealed class SupportTicketsController(SupportTicketService supportTicketService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<SupportTicketDto>>>> GetMyTickets(CancellationToken ct)
    {
        var result = await supportTicketService.GetUserTicketsAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<IReadOnlyList<SupportTicketDto>>.Ok(result));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<SupportTicketDto>>> Create(CreateSupportTicketRequest request, CancellationToken ct)
    {
        var result = await supportTicketService.CreateAsync(User.GetUserId(), request, ct);
        return Created(string.Empty, ApiResponse<SupportTicketDto>.Ok(result, "Destek talebi oluşturuldu."));
    }

    [HttpPost("replies")]
    public async Task<ActionResult<ApiResponse<SupportTicketReplyDto>>> AddReply(CreateSupportTicketReplyRequest request, CancellationToken ct)
    {
        var result = await supportTicketService.AddReplyAsync(User.GetUserId(), request, isStaff: false, ct);
        return Ok(ApiResponse<SupportTicketReplyDto>.Ok(result, "Yanıt eklendi."));
    }
}
