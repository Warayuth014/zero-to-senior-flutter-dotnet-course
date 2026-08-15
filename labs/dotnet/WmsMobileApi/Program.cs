using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
app.UseCors();

var tasks = new ConcurrentDictionary<string, MobileTask>(new[]
{
    KeyValuePair.Create("TASK-001", new MobileTask("TASK-001", "A-01", "PACK-01", "waiting")),
    KeyValuePair.Create("TASK-002", new MobileTask("TASK-002", "B-05", "OUT-02", "working")),
});

app.MapGet("/api/WMS/mobile_health", () => Results.Ok(new
{
    service = "wms-mobile-lab",
    status = "ok",
    serverTime = DateTimeOffset.UtcNow,
}));

app.MapGet("/api/WMS/mobile_tasks", () => Results.Ok(new
{
    items = tasks.Values.OrderBy(task => task.Id),
    totalCount = tasks.Count,
}));

app.MapPost("/api/WMS/mobile_tasks/{id}/complete", (string id) =>
    tasks.TryRemove(id, out _)
        ? Results.Ok(new { message = "completed", id })
        : Results.NotFound(new { message = $"ไม่พบ task {id}" }));

app.Run();

record MobileTask(string Id, string From, string To, string Status);
