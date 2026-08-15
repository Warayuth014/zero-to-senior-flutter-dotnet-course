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
var completedTasks = new ConcurrentDictionary<string, DateTimeOffset>();
var completedCommands = new ConcurrentDictionary<string, CompletionResponse>();
var taskGate = new object();

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

app.MapPost("/api/WMS/mobile_tasks/{id}/complete", (string id, HttpContext context) =>
{
    var commandId = context.Request.Headers["Idempotency-Key"].FirstOrDefault()?.Trim();
    if (string.IsNullOrWhiteSpace(commandId))
    {
        return Results.BadRequest(new { message = "ต้องส่ง Idempotency-Key" });
    }

    var correlationId = context.TraceIdentifier;
    context.Response.Headers["X-Correlation-ID"] = correlationId;

    lock (taskGate)
    {
        if (completedCommands.TryGetValue(commandId, out var cached))
        {
            if (!string.Equals(cached.Id, id, StringComparison.Ordinal))
            {
                return Results.Conflict(new
                {
                    message = "Idempotency-Key นี้ถูกใช้กับ task อื่นแล้ว",
                    correlationId,
                });
            }
            return Results.Ok(cached with { Replayed = true });
        }

        if (tasks.TryRemove(id, out _))
        {
            completedTasks[id] = DateTimeOffset.UtcNow;
            var completed = new CompletionResponse(id, false, false, correlationId);
            completedCommands[commandId] = completed;
            return Results.Ok(completed);
        }

        if (completedTasks.ContainsKey(id))
        {
            var alreadyCompleted = new CompletionResponse(id, true, false, correlationId);
            completedCommands[commandId] = alreadyCompleted;
            return Results.Ok(alreadyCompleted);
        }

        return Results.NotFound(new { message = $"ไม่พบ task {id}", correlationId });
    }
});

app.Run();

record MobileTask(string Id, string From, string To, string Status);
record CompletionResponse(
    string Id,
    bool AlreadyCompleted,
    bool Replayed,
    string CorrelationId);
