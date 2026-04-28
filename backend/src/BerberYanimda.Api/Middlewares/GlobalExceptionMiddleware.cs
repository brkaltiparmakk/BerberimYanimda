using System.Text.Json;
using BerberYanimda.Application.Common;

namespace BerberYanimda.Api.Middlewares;

public sealed class GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (AppException ex)
        {
            context.Response.StatusCode = ex.StatusCode;
            await WriteAsync(context, ApiResponse<object>.Fail(ex.Message, ex.Errors.ToList()));
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled API error");
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await WriteAsync(context, ApiResponse<object>.Fail("İşlem sırasında hata oluştu."));
        }
    }

    private static async Task WriteAsync(HttpContext context, ApiResponse<object> response)
    {
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync(JsonSerializer.Serialize(response, new JsonSerializerOptions(JsonSerializerDefaults.Web)));
    }
}
