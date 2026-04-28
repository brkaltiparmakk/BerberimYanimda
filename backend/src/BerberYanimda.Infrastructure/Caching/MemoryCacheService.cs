using System.Collections.Concurrent;
using BerberYanimda.Application.Interfaces;

namespace BerberYanimda.Infrastructure.Caching;

public sealed class MemoryCacheService : ICacheService
{
    private readonly ConcurrentDictionary<string, CacheEntry> _cache = new();

    public T? Get<T>(string key)
    {
        if (_cache.TryGetValue(key, out var entry) && entry.ExpiresAt > DateTime.UtcNow)
            return (T)entry.Value;
        _cache.TryRemove(key, out _);
        return default;
    }

    public void Set<T>(string key, T value, TimeSpan expiration)
    {
        _cache[key] = new CacheEntry(value!, DateTime.UtcNow.Add(expiration));
    }

    public void Remove(string key) => _cache.TryRemove(key, out _);

    private sealed record CacheEntry(object Value, DateTime ExpiresAt);
}
