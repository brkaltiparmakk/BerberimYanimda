namespace BerberYanimda.Application.Common;

public sealed class ApiResponse<T>
{
    public bool Success { get; init; }
    public string? Message { get; init; }
    public T? Data { get; init; }
    public List<ApiError>? Errors { get; init; }

    public static ApiResponse<T> Ok(T data, string? message = null) =>
        new() { Success = true, Data = data, Message = message };

    public static ApiResponse<T> Fail(string message, List<ApiError>? errors = null) =>
        new() { Success = false, Message = message, Errors = errors };
}

public sealed record ApiError(string? Field, string Message);

public sealed class PagedResponse<T>
{
    public IReadOnlyList<T> Items { get; init; } = [];
    public int Page { get; init; }
    public int PageSize { get; init; }
    public int TotalCount { get; init; }
    public int TotalPages { get; init; }
}

public sealed class AppException : Exception
{
    public int StatusCode { get; }
    public IReadOnlyList<ApiError> Errors { get; }

    public AppException(string message, int statusCode = 400, IReadOnlyList<ApiError>? errors = null)
        : base(message)
    {
        StatusCode = statusCode;
        Errors = errors ?? [];
    }
}
